/**
 * Default page number when not specified (1-based).
 */
export const DEFAULT_PAGE = 1;

/**
 * Default number of records per page when not specified.
 */
export const DEFAULT_LIMIT = 10;

/**
 * Maximum allowed value for limit (page size).
 */
export const MAX_LIMIT = 100;

/**
 * Regex to parse sort string in the form "field:ASC" or "field:DESC".
 */
export const SORT_PATTERN = /^(\w+):(ASC|DESC)$/i;
