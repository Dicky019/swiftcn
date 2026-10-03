//
//  SyncTypes.swift
//  Sources/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

import Foundation

/// One account and local store. Construct a new coordinator when this scope changes.
public struct SyncScope: Hashable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    precondition(!rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    self.rawValue = rawValue
  }
}

public enum SyncTrigger: Hashable, Sendable {
  case launch, foreground, manual, localMutation, connectivityHint
}

public enum RetryReason: Equatable, Sendable {
  case transport, timeout, serverBusy
}

public enum SyncBlockReason: Equatable, Sendable {
  case authentication, conflict, permanentRejection, storage, migration
}

public enum SyncPassResult: Equatable, Sendable {
  case noWork
  case completed
  case retry(reason: RetryReason, serverHint: Duration?)
  case blocked(SyncBlockReason)
  case expired
}

public enum SyncOutcome: Equatable, Sendable {
  case noWork
  case completed
  case deferred(RetryReason)
  case blocked(SyncBlockReason)
  case cancelled
  case expired
}

/// Feature-owned push, pull and reconciliation. Durable work remains in the adapter.
public protocol SyncWorker: Sendable {
  func run(scope: SyncScope, triggers: Set<SyncTrigger>) async -> SyncPassResult
}
