import "dotenv/config"
import fs from "node:fs"
import { getTokenAssetsKey } from "./colors-utils.js"
import { getSquidAssets } from "./colors.js"

const newTokensFilePath = "new-token-images.json"
const errorTokensFilePath = "url_fetch_errors.json"

;(async () => {
  console.log("Fetching latest tokens")

  const { tokens } = await getSquidAssets()

  const errorTokens = getErrorTokens()

  const errorTokensSet = new Set(errorTokens.tokens.map(getTokenAssetsKey))

  const newTokens = []

  for (const token of tokens) {
    const tokenKey = getTokenAssetsKey(token)
    const tokenAlreadyExists = fs.existsSync(
      `./images/migration/webp/${tokenKey}.webp`
    )

    if (tokenAlreadyExists) {
      continue
    }

    if (errorTokensSet.has(tokenKey)) {
      console.log(`Skipping token due to fetch error: ${token.symbol}`)
      continue
    }

    console.log(`New token added: ${token.symbol}`)
    newTokens.push(token)
  }

  fs.writeFileSync(
    `./scripts/update-tokens/${newTokensFilePath}`,
    JSON.stringify(
      newTokens.map(t => ({
        fileName: getTokenAssetsKey(t),
        imageUrl: t.logoURI
      })),
      null,
      2
    )
  )
  console.log(`Updated tokens saved to ${newTokensFilePath}`)
})()

function getErrorTokens() {
  try {
    return JSON.parse(
      fs.readFileSync(`./scripts/update-tokens/${errorTokensFilePath}`, "utf8")
    )
  } catch (error) {
    return {
      tokens: []
    }
  }
}
