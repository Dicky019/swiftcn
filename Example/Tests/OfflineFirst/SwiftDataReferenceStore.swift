//
//  SwiftDataReferenceStore.swift
//  Example/Tests/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

@testable import Example
import Foundation
import SwiftData

// Repository-only reference adapter. These models never ship in Sources/.
enum ReferenceSchemaV1: VersionedSchema {
  static let versionIdentifier = Schema.Version(1, 0, 0)
  static var models: [any PersistentModel.Type] { [ReferenceTodo.self, ReferenceOutbox.self, ReferenceCursor.self] }

  @Model final class ReferenceTodo {
    @Attribute(.unique) var key: String
    var id: UUID
    var scope: String
    var title: String
    var revision: Int
    var tombstone: Bool

    init(id: UUID, scope: String, title: String, revision: Int = 0, tombstone: Bool = false) {
      self.key = scope + ":" + id.uuidString
      self.id = id
      self.scope = scope
      self.title = title
      self.revision = revision
      self.tombstone = tombstone
    }
  }

  @Model final class ReferenceOutbox {
    @Attribute(.unique) var operationID: UUID
    var scope: String
    var entityID: UUID
    var commandVersion: Int
    var payload: Data
    var baseRevision: Int?
    var sequence: Int

    init(operationID: UUID, scope: String, entityID: UUID, payload: Data, sequence: Int, baseRevision: Int? = nil) {
      self.operationID = operationID
      self.scope = scope
      self.entityID = entityID
      self.commandVersion = 1
      self.payload = payload
      self.baseRevision = baseRevision
      self.sequence = sequence
    }
  }

  @Model final class ReferenceCursor {
    @Attribute(.unique) var scope: String
    var value: String
    init(scope: String, value: String) {
      self.scope = scope
      self.value = value
    }
  }
}

enum ReferenceSchemaV2: VersionedSchema {
  static let versionIdentifier = Schema.Version(2, 0, 0)
  static var models: [any PersistentModel.Type] { [ReferenceTodo.self, ReferenceOutbox.self, ReferenceCursor.self] }
  typealias ReferenceTodo = ReferenceSchemaV1.ReferenceTodo
  typealias ReferenceCursor = ReferenceSchemaV1.ReferenceCursor

  @Model final class ReferenceOutbox {
    @Attribute(.unique) var operationID: UUID
    var scope: String
    var entityID: UUID
    var commandVersion: Int
    var payload: Data
    var baseRevision: Int?
    var sequence: Int
    var attemptCount: Int?
    var nextAttemptDate: Date?

    init(operationID: UUID, scope: String, entityID: UUID, payload: Data, sequence: Int, baseRevision: Int? = nil) {
      self.operationID = operationID
      self.scope = scope
      self.entityID = entityID
      self.commandVersion = 1
      self.payload = payload
      self.baseRevision = baseRevision
      self.sequence = sequence
    }
  }
}

enum ReferenceMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [ReferenceSchemaV1.self, ReferenceSchemaV2.self] }
  static var stages: [MigrationStage] {
    [.lightweight(fromVersion: ReferenceSchemaV1.self, toVersion: ReferenceSchemaV2.self)]
  }
}

typealias ReferenceTodo = ReferenceSchemaV2.ReferenceTodo
typealias ReferenceOutbox = ReferenceSchemaV2.ReferenceOutbox
typealias ReferenceCursor = ReferenceSchemaV2.ReferenceCursor

enum ReferenceStoreError: Error, Equatable {
  case injectedFailure
  case operationCollision
}

struct ReferenceDiskChange: Sendable {
  let id: UUID
  let title: String
  let revision: Int
  let tombstone: Bool
}

@MainActor
final class SwiftDataReferenceStore {
  private let container: ModelContainer
  private let context: ModelContext

  init(url: URL, readOnly: Bool = false) throws {
    let schema = Schema(versionedSchema: ReferenceSchemaV2.self)
    let configuration = ModelConfiguration(schema: schema, url: url, allowsSave: !readOnly)
    self.container = try ModelContainer(for: schema, migrationPlan: ReferenceMigrationPlan.self, configurations: configuration)
    self.context = ModelContext(container)
    context.autosaveEnabled = false
  }

  func todo(id: UUID, scope: SyncScope) throws -> ReferenceTodo? {
    let key = scope.rawValue + ":" + id.uuidString
    return try context.fetch(FetchDescriptor<ReferenceTodo>(predicate: #Predicate { $0.key == key })).first
  }

  func pending(scope: SyncScope) throws -> [ReferenceOutbox] {
    let rawScope = scope.rawValue
    return try context.fetch(FetchDescriptor<ReferenceOutbox>(
      predicate: #Predicate { $0.scope == rawScope },
      sortBy: [SortDescriptor(\ReferenceOutbox.sequence)]
    ))
  }

  func all(scope: SyncScope) throws -> [ReferenceTodo] {
    let rawScope = scope.rawValue
    return try context.fetch(FetchDescriptor<ReferenceTodo>(predicate: #Predicate { $0.scope == rawScope }))
  }

  func visible(scope: SyncScope) throws -> [ReferenceTodo] {
    try all(scope: scope).filter { !$0.tombstone }
  }

  func cursor(scope: SyncScope) throws -> String? { try cursorRow(scope: scope)?.value }

  func saveTodoAndEnqueue(id: UUID, title: String, operationID: UUID, scope: SyncScope, failBeforeCommit: Bool = false) throws {
    try transaction {
      if let existing = try operation(operationID) {
        guard existing.entityID == id, existing.scope == scope.rawValue, existing.payload == Data(title.utf8) else {
          throw ReferenceStoreError.operationCollision
        }
        return
      }
      let current = try todo(id: id, scope: scope)
      let baseRevision = current?.revision
      if let current {
        current.title = title
        current.tombstone = false
      } else {
        context.insert(ReferenceTodo(id: id, scope: scope.rawValue, title: title))
      }
      let sequence = (try pending(scope: scope).map(\.sequence).max() ?? 0) + 1
      context.insert(ReferenceOutbox(
        operationID: operationID,
        scope: scope.rawValue,
        entityID: id,
        payload: Data(title.utf8),
        sequence: sequence,
        baseRevision: baseRevision
      ))
      if failBeforeCommit { throw ReferenceStoreError.injectedFailure }
    }
  }

  func acknowledge(operationID: UUID, serverRevision: Int, failBeforeCommit: Bool = false) throws {
    try transaction {
      guard let row = try operation(operationID) else { return }
      let scope = SyncScope(rawValue: row.scope)
      if let entity = try todo(id: row.entityID, scope: scope) {
        entity.revision = max(entity.revision, serverRevision)
      }
      context.delete(row)
      if failBeforeCommit { throw ReferenceStoreError.injectedFailure }
    }
  }

  func apply(changes: [ReferenceDiskChange], cursor: String, scope: SyncScope, failBeforeCommit: Bool = false) throws {
    try transaction {
      let pendingIDs = Set(try pending(scope: scope).map(\.entityID))
      for change in changes {
        if let entity = try todo(id: change.id, scope: scope) {
          // The reference conflict policy preserves pending local projection.
          guard !pendingIDs.contains(change.id), change.revision > entity.revision else { continue }
          entity.title = change.title
          entity.revision = change.revision
          entity.tombstone = change.tombstone
        } else {
          context.insert(ReferenceTodo(
            id: change.id,
            scope: scope.rawValue,
            title: change.title,
            revision: change.revision,
            tombstone: change.tombstone
          ))
        }
      }
      if let row = try cursorRow(scope: scope) { row.value = cursor } else {
        context.insert(ReferenceCursor(scope: scope.rawValue, value: cursor))
      }
      if failBeforeCommit { throw ReferenceStoreError.injectedFailure }
    }
  }

  private func operation(_ id: UUID) throws -> ReferenceOutbox? {
    try context.fetch(FetchDescriptor<ReferenceOutbox>(predicate: #Predicate { $0.operationID == id })).first
  }

  private func cursorRow(scope: SyncScope) throws -> ReferenceCursor? {
    let rawScope = scope.rawValue
    return try context.fetch(FetchDescriptor<ReferenceCursor>(predicate: #Predicate { $0.scope == rawScope })).first
  }

  private func transaction(_ mutation: () throws -> Void) throws {
    do { try context.transaction(block: mutation) } catch {
      // A thrown transaction closure can leave dirty models in its context.
      // Explicit rollback also prevents a later transaction committing them.
      context.rollback()
      throw error
    }
  }
}
