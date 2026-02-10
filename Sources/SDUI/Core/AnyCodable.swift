//
//  AnyCodable.swift
//  Sources/SDUI/Core
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

/// Type-erased Codable wrapper for heterogeneous props
/// Supports: String, Int, Double, Bool, [AnyCodable], [String: AnyCodable]
public enum AnyCodable: Codable, Sendable, Hashable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case array([AnyCodable])
  case dictionary([String: AnyCodable])
  case null

  public var value: Any {
    switch self {
    case .string(let v): return v
    case .int(let v): return v
    case .double(let v): return v
    case .bool(let v): return v
    case .array(let v): return v.map { $0.value }
    case .dictionary(let v): return v.mapValues { $0.value }
    case .null: return NSNull()
    }
  }

  public init(_ value: Any) {
    switch value {
    case let string as String:
      self = .string(string)
    case let int as Int:
      self = .int(int)
    case let double as Double:
      self = .double(double)
    case let bool as Bool:
      self = .bool(bool)
    case let array as [Any]:
      self = .array(array.map { AnyCodable($0) })
    case let dict as [String: Any]:
      self = .dictionary(dict.mapValues { AnyCodable($0) })
    default:
      self = .null
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let string = try? container.decode(String.self) {
      self = .string(string)
    } else if let int = try? container.decode(Int.self) {
      self = .int(int)
    } else if let double = try? container.decode(Double.self) {
      self = .double(double)
    } else if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
    } else if let array = try? container.decode([AnyCodable].self) {
      self = .array(array)
    } else if let dict = try? container.decode([String: AnyCodable].self) {
      self = .dictionary(dict)
    } else {
      self = .null
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let v): try container.encode(v)
    case .int(let v): try container.encode(v)
    case .double(let v): try container.encode(v)
    case .bool(let v): try container.encode(v)
    case .array(let v): try container.encode(v)
    case .dictionary(let v): try container.encode(v)
    case .null: try container.encodeNil()
    }
  }
}
