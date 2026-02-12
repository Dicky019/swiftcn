//
//  SDUIError.swift
//  Sources/SDUI/Core
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

public enum SDUIError: Error, LocalizedError {
  case invalidJSON
  case componentNotFound(String)
  case decodingFailed(Error)
  case maxDepthExceeded(Int)
  case payloadTooLarge(Int)
  case maxNodeCountExceeded(Int)

  public var errorDescription: String? {
    switch self {
    case .invalidJSON:
      return "Invalid JSON data"
    case .componentNotFound(let type):
      return "Component not found: \(type)"
    case .decodingFailed(let error):
      return "Decoding failed: \(error.localizedDescription)"
    case .maxDepthExceeded(let depth):
      return "SDUI tree exceeds maximum depth of \(depth)"
    case .payloadTooLarge(let size):
      return "SDUI payload size \(size) bytes exceeds maximum"
    case .maxNodeCountExceeded(let count):
      return "SDUI tree exceeds maximum node count of \(count)"
    }
  }
}
