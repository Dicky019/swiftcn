//
//  SDUIError.swift
//  Source/SDUI/Core
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

public enum SDUIError: Error, LocalizedError {
    case invalidJSON
    case componentNotFound(String)
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON data"
        case .componentNotFound(let type):
            return "Component not found: \(type)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        }
    }
}
