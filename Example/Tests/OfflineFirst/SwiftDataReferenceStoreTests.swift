//
//  SwiftDataReferenceStoreTests.swift
//  Example/Tests/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

@testable import Example
import Foundation
import SwiftData
import Testing

struct ReferenceDiskFixture {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  var url: URL { root.appendingPathComponent("offline.store") }
  init() throws { try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
  func remove() { try? FileManager.default.removeItem(at: root) }
}

@Suite("SwiftData durable offline contracts")
@MainActor
struct SwiftDataReferenceStoreTests {
  let scope = SyncScope(rawValue: "account-A")

  @Test func localProjectionAndOutboxSurviveActualReopen() throws {
    let disk = try ReferenceDiskFixture()
    defer { disk.remove() }
    let id = UUID(), operation = UUID()
    do {
      let store = try SwiftDataReferenceStore(url: disk.url)
      try store.saveTodoAndEnqueue(id: id, title: "local", operationID: operation, scope: scope)
    }
    let reopened = try SwiftDataReferenceStore(url: disk.url)
    #expect(try reopened.todo(id: id, scope: scope)?.title == "local")
    let pending = try reopened.pending(scope: scope)
    #expect(pending.map(\.operationID) == [operation])
    #expect(pending.first?.commandVersion == 1)
    #expect(pending.first?.payload == Data("local".utf8))
  }

  @Test func failedTransactionRollsBackBothInMemoryAndOnDisk() throws {
    let disk = try ReferenceDiskFixture()
    defer { disk.remove() }
    let id = UUID(), operation = UUID()
    let store = try SwiftDataReferenceStore(url: disk.url)
    #expect(throws: ReferenceStoreError.injectedFailure) {
      try store.saveTodoAndEnqueue(id: id, title: "lost", operationID: operation, scope: scope, failBeforeCommit: true)
    }
    #expect(try store.todo(id: id, scope: scope) == nil)
    #expect(try store.pending(scope: scope).isEmpty)
    // A later successful transaction must not accidentally commit rolled-back work.
    try store.saveTodoAndEnqueue(id: UUID(), title: "other", operationID: UUID(), scope: scope)
    let reopened = try SwiftDataReferenceStore(url: disk.url)
    #expect(try reopened.todo(id: id, scope: scope) == nil)
    #expect(try reopened.pending(scope: scope).count == 1)
  }

  @Test func acknowledgmentIsAtomicAndLateAckKeepsLaterEdit() throws {
    let disk = try ReferenceDiskFixture()
    defer { disk.remove() }
    let id = UUID(), first = UUID(), second = UUID()
    do {
      let store = try SwiftDataReferenceStore(url: disk.url)
      try store.saveTodoAndEnqueue(id: id, title: "first", operationID: first, scope: scope)
      try store.saveTodoAndEnqueue(id: id, title: "second", operationID: second, scope: scope)
      #expect(throws: ReferenceStoreError.injectedFailure) {
        try store.acknowledge(operationID: first, serverRevision: 7, failBeforeCommit: true)
      }
      #expect(try store.todo(id: id, scope: scope)?.revision == 0)
      #expect(try store.pending(scope: scope).map(\.operationID) == [first, second])
      try store.acknowledge(operationID: first, serverRevision: 7)
    }
    let reopened = try SwiftDataReferenceStore(url: disk.url)
    #expect(try reopened.todo(id: id, scope: scope)?.title == "second")
    #expect(try reopened.todo(id: id, scope: scope)?.revision == 7)
    #expect(try reopened.pending(scope: scope).map(\.operationID) == [second])
  }

  @Test func pageAndCursorCommitTogetherAndReplayPreservesTombstone() throws {
    let disk = try ReferenceDiskFixture()
    defer { disk.remove() }
    let id = UUID()
    let store = try SwiftDataReferenceStore(url: disk.url)
    let first = ReferenceDiskChange(id: id, title: "remote", revision: 1, tombstone: false)
    try store.apply(changes: [first], cursor: "1", scope: scope)
    let deleted = ReferenceDiskChange(id: id, title: "remote", revision: 2, tombstone: true)
    #expect(throws: ReferenceStoreError.injectedFailure) {
      try store.apply(changes: [deleted], cursor: "2", scope: scope, failBeforeCommit: true)
    }
    let afterFailure = try SwiftDataReferenceStore(url: disk.url)
    #expect(try afterFailure.cursor(scope: scope) == "1")
    #expect(try afterFailure.todo(id: id, scope: scope)?.tombstone == false)
    try store.apply(changes: [deleted], cursor: "2", scope: scope)
    try store.apply(changes: [deleted], cursor: "2", scope: scope)
    try store.apply(changes: [first], cursor: "2", scope: scope)
    let reopened = try SwiftDataReferenceStore(url: disk.url)
    #expect(try reopened.cursor(scope: scope) == "2")
    #expect(try reopened.todo(id: id, scope: scope)?.tombstone == true)
    #expect(try reopened.visible(scope: scope).isEmpty)
    #expect(try reopened.all(scope: scope).count == 1)
  }

  @Test func operationDeduplicationAndAccountIsolation() throws {
    let disk = try ReferenceDiskFixture()
    defer { disk.remove() }
    let id = UUID(), operation = UUID(), otherOperation = UUID()
    let other = SyncScope(rawValue: "account-B")
    let store = try SwiftDataReferenceStore(url: disk.url)
    try store.saveTodoAndEnqueue(id: id, title: "A", operationID: operation, scope: scope)
    try store.saveTodoAndEnqueue(id: id, title: "A", operationID: operation, scope: scope)
    try store.saveTodoAndEnqueue(id: id, title: "B", operationID: otherOperation, scope: other)
    try store.apply(changes: [], cursor: "A-cursor", scope: scope)
    #expect(try store.pending(scope: scope).map(\.operationID) == [operation])
    #expect(try store.pending(scope: other).map(\.operationID) == [otherOperation])
    #expect(try store.todo(id: id, scope: scope)?.title == "A")
    #expect(try store.todo(id: id, scope: other)?.title == "B")
    #expect(try store.cursor(scope: other) == nil)
  }

  @Test func actualReadOnlyDiskSaveFailurePropagates() throws {
    let disk = try ReferenceDiskFixture()
    defer { disk.remove() }
    let id = UUID(), operation = UUID()
    do { _ = try SwiftDataReferenceStore(url: disk.url) }
    let readOnly = try SwiftDataReferenceStore(url: disk.url, readOnly: true)
    #expect(throws: (any Error).self) {
      try readOnly.saveTodoAndEnqueue(id: id, title: "unsaved", operationID: operation, scope: scope)
    }
    #expect(try readOnly.todo(id: id, scope: scope) == nil)
    let reopened = try SwiftDataReferenceStore(url: disk.url)
    #expect(try reopened.todo(id: id, scope: scope) == nil)
    #expect(try reopened.pending(scope: scope).isEmpty)
  }

  @Test func lightweightMigrationPreservesPendingOperationAndPayload() throws {
    let disk = try ReferenceDiskFixture()
    defer { disk.remove() }
    let operation = UUID(), id = UUID()
    do {
      let schema = Schema(versionedSchema: ReferenceSchemaV1.self)
      let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: disk.url))
      let context = ModelContext(container)
      context.autosaveEnabled = false
      context.insert(ReferenceSchemaV1.ReferenceOutbox(
        operationID: operation,
        scope: scope.rawValue,
        entityID: id,
        payload: Data("before migration".utf8),
        sequence: 1
      ))
      try context.save()
    }
    let migrated = try SwiftDataReferenceStore(url: disk.url)
    let pending = try migrated.pending(scope: scope)
    #expect(pending.map(\.operationID) == [operation])
    #expect(pending.first?.payload == Data("before migration".utf8))
    #expect(pending.first?.attemptCount == nil)
    #expect(pending.first?.nextAttemptDate == nil)
  }
}
