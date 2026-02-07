/**
 * Constants for swiftcn CLI
 * Centralized configuration values and allowed paths
 */

import { createRequire } from 'node:module'

const require = createRequire(import.meta.url)
const packageJson = require('../../package.json')

/**
 * CLI version (single source of truth from package.json)
 */
export const VERSION: string = packageJson.version

/**
 * Allowed repository URLs for cloning
 * Only repositories in this list can be used as sources
 */
export const ALLOWED_REPO_URLS = [
  'https://github.com/Dicky019/swiftcn.git'
] as const

/**
 * Allowed source paths within the repository
 * Files can only be copied from these subdirectories
 */
export const ALLOWED_SOURCE_PATHS = [
  'Sources/Components',
  'Sources/Theme',
  'Sources/SDUI'
] as const

/**
 * Configuration file name
 */
export const CONFIG_FILE_NAME = 'swiftcn.json'

/**
 * Base source directory name
 */
export const SOURCE_PATH = 'Sources'

/**
 * Remote registry URL (fetched from GitHub raw)
 */
export const REGISTRY_URL = 'https://raw.githubusercontent.com/Dicky019/swiftcn/main/CLI/registry.json'

/**
 * Maximum allowed length for component names
 */
export const MAX_COMPONENT_NAME_LENGTH = 50
