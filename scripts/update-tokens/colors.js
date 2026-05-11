// ENTRY SCRIPT — do not import this file from anywhere.
// This runs `main()` at module load; importing it would trigger an unintended
// full color-extraction pass (and re-fetch all Squid data).
// Shared helpers live in `./squid-api.js` and `./colors-utils.js`.

import "dotenv/config"
import chalk from "chalk"
import fs from "node:fs"
import fsp from "node:fs/promises"
import { pathToFileURL } from "node:url"
import {
  getTokenAssetsKey,
  getAverageColor,
  getContrastColor
} from "./colors-utils.js"
import { getSquidAssets } from "./squid-api.js"

if (import.meta.url !== pathToFileURL(process.argv[1]).href) {
  throw new Error(
    "colors.js is an entry script and must not be imported. " +
      "Import shared helpers from ./squid-api.js or ./colors-utils.js instead."
  )
}

const colorsFilePath = "scripts/update-tokens/colors.json"
const failedUrlsFilePath = "scripts/update-tokens/url_fetch_errors.json"
const defaultChainBgColor = ""
const defaultTokenBgColor = ""
const defaultTokenTextColor = ""
const TOKEN_CONCURRENCY = 16

const defaultColors = { tokens: {}, chains: {} }
const getSavedColors = () => {
  try {
    const data = fs.readFileSync(colorsFilePath, "utf8")
    return JSON.parse(data)
  } catch (error) {
    // create the file if it doesn't exist
    if (error.code === "ENOENT") {
      fs.writeFileSync(colorsFilePath, JSON.stringify(defaultColors))
      return defaultColors
    }

    console.error("Error reading colors file:", error)
    return defaultColors
  }
}

async function saveColors(colors) {
  try {
    await fsp.writeFile(colorsFilePath, JSON.stringify(colors, null, 2))
    console.log(chalk.greenBright(`\nColors saved to ${colorsFilePath}`))
  } catch (err) {
    console.error("Error writing colors to file:", err)
  }
}

async function saveFailedUrls(failedUrls) {
  try {
    await fsp.writeFile(failedUrlsFilePath, JSON.stringify(failedUrls, null, 2))
    console.log(
      chalk.greenBright(`\nFailed urls saved to ${failedUrlsFilePath}`)
    )
  } catch (err) {
    console.error("Error writing failed urls to file:", err)
  }
}

function getRgbKeys(color) {
  const [r = 0, g = 0, b = 0] = color.match(/\d+/g)

  return {
    r: Number(r),
    g: Number(g),
    b: Number(b)
  }
}

// Use png instead of webp, as webp is not supported by node canvas
const getTokenImage = token =>
  `images/migration/png/${getTokenAssetsKey(token)}.png`

const getChainImage = chain => {
  return chain.chainIconURI.replaceAll("webp", "png")
}

async function main() {
  console.log("Extracting assets colors")

  const squidData = await getSquidAssets()

  // Add safety checks for destructuring
  const { tokens = [], chains = [] } = squidData || {}

  if (chains.length === 0) {
    console.log(chalk.yellow("No chains data available. Skipping chain processing."))
  }

  if (tokens.length === 0) {
    console.log(chalk.yellow("No tokens data available. Skipping token processing."))
  }

  const chainIdToNameMapping = chains.reduce((acc, chain) => {
    acc[chain.chainId] = chain.networkName
    return acc
  }, {})

  const colors = getSavedColors()
  const failedUrls = {
    chains: [],
    tokens: []
  }

  const chainColorPromises = []

  for (const chain of chains) {
    if (!!colors.chains[chain.chainId]?.bgColor) {
      continue
    }

    const chainPromise = getAverageColor(getChainImage(chain))
      .then(chainBgColor => {
        colors.chains[chain.chainId] = {
          bgColor: chainBgColor
        }

        const { r, g, b } = getRgbKeys(chainBgColor)

        console.log(chalk.rgb(r, g, b)(`Chain ${chain.networkName} saved`))
      })
      .catch(error => {
        console.error(
          chalk.bgRed.white.underline.bold(
            `Error fetching image for chain ${chain.networkName}`
          ),
          error.message
        )
        console.log("at", chalk.blueBright(getChainImage(chain)), "\n")

        colors.chains[chain.chainId] = {
          bgColor: defaultChainBgColor
        }

        failedUrls.chains.push({
          id: chain.chainId,
          name: chain.networkName,
          fileName: getChainImage(chain)
        })

        console.log(
          chalk.grey(`Chain ${chain.networkName} saved using fallback color`)
        )
      })
    chainColorPromises.push(chainPromise)
  }

  await Promise.all(chainColorPromises)

  // Ensure every chain referenced by a token has at least a default entry
  for (const token of tokens) {
    if (!colors.chains[token.chainId]) {
      colors.chains[token.chainId] = { bgColor: defaultChainBgColor }
    }
  }

  const tokensToProcess = tokens.filter(
    token => !colors.tokens[getTokenAssetsKey(token)]?.bgColor
  )

  const processToken = async token => {
    try {
      const tokenBgColor = await getAverageColor(getTokenImage(token))
      const { r, g, b } = getRgbKeys(tokenBgColor)
      const tokenTextColor = getContrastColor({ r, g, b })

      colors.tokens[getTokenAssetsKey(token)] = {
        bgColor: tokenBgColor,
        textColor: tokenTextColor
      }
      console.log(
        chalk.rgb(r, g, b)(
          `Token ${token.symbol} on ${chainIdToNameMapping[token.chainId]} saved`
        )
      )
    } catch (error) {
      console.error(
        chalk.bgRed.white.underline.bold(
          `Error fetching image for token ${token.symbol} on ${chainIdToNameMapping[token.chainId]}:`
        ),
        error.message
      )
      console.log("at", chalk.blueBright(token.logoURI))
      console.log(
        chalk.grey(
          `Token ${token.symbol} on ${chainIdToNameMapping[token.chainId]} saved using fallback colors`
        ),
        "\n"
      )

      colors.tokens[getTokenAssetsKey(token)] = {
        bgColor: defaultTokenBgColor,
        textColor: defaultTokenTextColor
      }
      failedUrls.tokens.push({
        symbol: token.symbol,
        chainId: token.chainId,
        address: token.address,
        fileName: getTokenImage(token),
        originalUrl: token.logoURI
      })
    }
  }

  for (let i = 0; i < tokensToProcess.length; i += TOKEN_CONCURRENCY) {
    const batch = tokensToProcess.slice(i, i + TOKEN_CONCURRENCY)
    await Promise.all(batch.map(processToken))
  }

  await Promise.all([saveColors(colors), saveFailedUrls(failedUrls)])
}

main()
