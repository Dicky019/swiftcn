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
 * Configuration file name
 */
export const CONFIG_FILE_NAME = 'swiftcn.json'

/**
 * Base source directory name
 */
export const SOURCE_PATH = 'Sources'

/**
 * Git reference matching the CLI release version
 */
export const SOURCE_REF = `v${VERSION}`

/**
 * Remote registry URL (fetched from GitHub raw)
 */
export const REGISTRY_URL = `https://raw.githubusercontent.com/Dicky019/swiftcn/${SOURCE_REF}/CLI/registry.json`

/**
 * Maximum allowed length for component names
 */
export const MAX_COMPONENT_NAME_LENGTH = 50
