import fs from "node:fs"
import { getTokenAssetsKey } from "./colors-utils.js"

const newTokensFilePath = "new-token-images.json"

;(async () => {
  console.log("Fetching latest tokens")
  const response = await fetch("https://api.uatsquidrouter.com/v2/sdk-info", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      "x-integrator-id": "squid-swap-widget"
    }
  })

  const { tokens } = await response.json()

  const newTokens = []

  for (const token of tokens) {
    const tokenAlreadyExists = fs.existsSync(
      `./images/migration/webp/${getTokenAssetsKey(token)}.webp`
    )

    if (!tokenAlreadyExists) {
      console.log(`New token added: ${token.symbol}`)
      newTokens.push(token)
    }
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
  console.log(`missing tokens saved to ${newTokensFilePath}`)
})()
