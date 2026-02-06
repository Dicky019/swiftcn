/**
 * Error handling utilities for swiftcn CLI
 * Provides structured error types with error codes
 */

/**
 * Error codes for different failure scenarios
 */
export enum ErrorCode {
  CONFIG_NOT_FOUND = 'CONFIG_NOT_FOUND',
  COMPONENT_NOT_FOUND = 'COMPONENT_NOT_FOUND',
  PATH_TRAVERSAL = 'PATH_TRAVERSAL',
  INVALID_INPUT = 'INVALID_INPUT',
  GIT_CLONE_FAILED = 'GIT_CLONE_FAILED',
  FILE_COPY_FAILED = 'FILE_COPY_FAILED',
  REGISTRY_LOAD_FAILED = 'REGISTRY_LOAD_FAILED',
}

/**
 * Custom error class for swiftcn CLI operations
 * Extends native Error with structured error codes
 */
export class SwiftCNError extends Error {
  public readonly code: ErrorCode

  constructor(message: string, code: ErrorCode) {
    super(message)
    this.name = 'SwiftCNError'
    this.code = code

    // Maintains proper stack trace for where our error was thrown (only available on V8)
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, SwiftCNError)
    }
  }
}
