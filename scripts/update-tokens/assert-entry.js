import { pathToFileURL } from "node:url"

/**
 * Throws if the calling module is being imported instead of executed as the
 * main entry script. Call from the top of any file that runs side effects on
 * load (entry scripts) so accidental imports fail loudly.
 *
 * Usage:
 *   import { assertEntry } from "./assert-entry.js"
 *   assertEntry(import.meta)
 */
export function assertEntry(meta) {
  if (
    !process.argv[1] ||
    meta.url !== pathToFileURL(process.argv[1]).href
  ) {
    const filename = meta.url.split("/").pop()
    throw new Error(
      `${filename} is an entry script and must not be imported. ` +
        "Import shared helpers from ./squid-api.js or ./colors-utils.js instead."
    )
  }
}
