/**
 * Path sanitization and validation utilities
 * Prevents path traversal attacks and validates user input
 */

import path from 'node:path'
import { SwiftCNError, ErrorCode } from './errors.js'
import { MAX_COMPONENT_NAME_LENGTH } from './constants.js'

/**
 * Sanitizes a path by normalizing and validating it
 * @param inputPath - The path to sanitize
 * @returns The sanitized path
 * @throws {SwiftCNError} If path contains invalid characters or patterns
 */
export function sanitizePath(inputPath: string): string {
  if (!inputPath || typeof inputPath !== 'string') {
    throw new SwiftCNError('Path must be a non-empty string', ErrorCode.INVALID_INPUT)
  }

  // Trim whitespace
  const trimmed = inputPath.trim()

  if (trimmed.length === 0) {
    throw new SwiftCNError('Path cannot be empty', ErrorCode.INVALID_INPUT)
  }

  // Normalize the path to remove redundant separators and resolve . and ..
  const normalized = path.normalize(trimmed)

  // Check for path traversal after normalization
  if (isPathTraversal(normalized)) {
    throw new SwiftCNError(
      'Path contains path traversal patterns (..)',
      ErrorCode.PATH_TRAVERSAL
    )
  }

  return normalized
}

/**
 * Checks if a path contains path traversal attempts
 * @param inputPath - The path to check
 * @returns true if path contains traversal patterns
 */
export function isPathTraversal(inputPath: string): boolean {
  // Check for .. in the path
  const parts = inputPath.split(path.sep)
  return parts.includes('..')
}

/**
 * Resolves a relative path against a base path securely
 * Ensures the resolved path stays within the base directory
 * @param basePath - The base directory path
 * @param relativePath - The relative path to resolve
 * @returns The resolved absolute path
 * @throws {SwiftCNError} If the resolved path is outside the base directory
 */
export function resolveSecurePath(basePath: string, relativePath: string): string {
  // Reject absolute paths in user input
  if (path.isAbsolute(relativePath)) {
    throw new SwiftCNError(
      'Relative path cannot be absolute',
      ErrorCode.PATH_TRAVERSAL
    )
  }

  // Sanitize the relative path first
  const sanitized = sanitizePath(relativePath)

  // Resolve the path against the base
  const resolved = path.resolve(basePath, sanitized)

  // Normalize both paths for comparison
  const normalizedBase = path.resolve(basePath)
  const normalizedResolved = path.resolve(resolved)

  // Ensure the resolved path is within the base directory
  if (!normalizedResolved.startsWith(normalizedBase + path.sep) &&
      normalizedResolved !== normalizedBase) {
    throw new SwiftCNError(
      'Resolved path is outside the allowed directory',
      ErrorCode.PATH_TRAVERSAL
    )
  }

  return resolved
}

/**
 * Validates a component name
 * Component names must be alphanumeric with optional hyphens, max 50 chars
 * @param name - The component name to validate
 * @returns true if the name is valid
 */
export function isValidComponentName(name: string): boolean {
  if (!name || typeof name !== 'string') {
    return false
  }

  // Check length
  if (name.length === 0 || name.length > MAX_COMPONENT_NAME_LENGTH) {
    return false
  }

  // Check pattern: alphanumeric + hyphen only
  // Must start and end with alphanumeric (not hyphen)
  const pattern = /^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$/
  return pattern.test(name)
}
