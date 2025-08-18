import "dotenv/config"
import chalk from "chalk"
import fs from "node:fs"
import {
  getTokenAssetsKey,
  getAverageColor,
  getContrastColor,
  isEvmosChain,
  isSolanaSanctumAutomatedToken,
  nativeEvmTokenAddress
} from "./colors-utils.js"
const colorsFilePath = "scripts/update-tokens/colors.json"
const failedUrlsFilePath = "scripts/update-tokens/url_fetch_errors.json"
const defaultChainBgColor = ""
const defaultTokenBgColor = ""
const defaultTokenTextColor = ""

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

export const getSquidAssets = async (retries = 3) => {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      console.log(`Attempting to fetch Squid data (attempt ${attempt}/${retries})...`)
      
      const url = new URL("/v2/sdk-info", process.env.SQUID_API_URL)
      
      // Add timeout to the fetch request
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 30000) // 30 second timeout
      
      const response = await fetch(url, {
        headers: {
          "Content-Type": "application/json",
          "x-integrator-id": process.env.SQUID_INTEGRATOR_ID
        },
        signal: controller.signal
      })

      clearTimeout(timeoutId)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      validateSdkInfo(data)

      // remove sanctum automated tokens
      data.tokens = data.tokens.filter(t => !isSolanaSanctumAutomatedToken(t))

      const evmosChains = data.chains.filter(isEvmosChain)
      const evmosChainIds = evmosChains.map(c => c.chainId)

      const evmosNativeTokenAddressesMap = evmosChains.reduce((acc, chain) => {
        const normalizedSymbol = chain.nativeCurrency.symbol.toLowerCase()

        return {
          ...acc,
          [normalizedSymbol]: nativeEvmTokenAddress
        }
      }, {})

      /**
       * Converts an evmos address (erc20/0x123...abc)
       * to an evm standard address (0x123...abc)
       *
       * Also gas tokens on evmos chains have non-standard EVM addresses
       * so we need to map them to the native EVM token address
       */
      const evmosAddressToEvmAddress = address => {
        if (evmosNativeTokenAddressesMap[address]) {
          return evmosNativeTokenAddressesMap[address]
        }

        return address.replace(/^erc20\//, "")
      }

      data.tokens = data.tokens.map(token => {
        const isEvmosToken = evmosChainIds.includes(token.chainId)

        return {
          ...token,
          address: isEvmosToken
            ? // convert evmos address (erc20/0x123...abc) to evm address (0x123...abc)
              evmosAddressToEvmAddress(token.address)
            : token.address
        }
      })

      console.log(chalk.green(`Successfully fetched ${data.chains.length} chains and ${data.tokens.length} tokens`))
      return data
      
    } catch (error) {
      console.error(`Attempt ${attempt} failed:`, error.message)
      
      if (attempt === retries) {
        console.error(chalk.red("All attempts failed. Returning empty data structure."))
        // Return proper structure instead of empty array
        return { chains: [], tokens: [] }
      }
      
      // Wait before retrying (exponential backoff)
      const waitTime = Math.pow(2, attempt) * 1000
      console.log(chalk.yellow(`Waiting ${waitTime}ms before retry...`))
      await sleep(waitTime)
    }
  }
}

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

function saveColors(colors) {
  fs.writeFile(colorsFilePath, JSON.stringify(colors, null, 2), err => {
    if (err) {
      console.error("Error writing colors to file:", err)
    } else {
      console.log(chalk.greenBright(`\nColors saved to ${colorsFilePath}`))
    }
  })
}

function saveFailedUrls(failedUrls) {
  fs.writeFile(failedUrlsFilePath, JSON.stringify(failedUrls, null, 2), err => {
    if (err) {
      console.error("Error writing failed urls to file:", err)
    } else {
      console.log(
        chalk.greenBright(`\nFailed urls saved to ${failedUrlsFilePath}`)
      )
    }
  })
}

;(async function main() {
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
      // console.log(
      //   chalk.grey(
      //     `Chain ${chain.networkName} (${chain.chainId}) already exists, skipping`
      //   )
      // )
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

  for await (const token of tokens) {
    // add chain object if it doesn't exist
    if (!colors.chains[token.chainId]) {
      colors.chains[token.chainId] = {
        bgColor: defaultChainBgColor
      }
    }

    const tokenAlreadyExists =
      !!colors.tokens[getTokenAssetsKey(token)]?.bgColor

    if (tokenAlreadyExists) {
      // console.log(
      //   chalk.grey(
      //     `Token ${token.symbol} on ${
      //       chainIdToNameMapping[token.chainId]
      //     } already exists, skipping`
      //   )
      // )
      continue
    }

    await sleep(100)
    try {
      const tokenBgColor = await getAverageColor(getTokenImage(token))
      const { r, g, b } = getRgbKeys(tokenBgColor)
      const tokenTextColor = getContrastColor({ r, g, b })

      colors.tokens[getTokenAssetsKey(token)] = {
        bgColor: tokenBgColor,
        textColor: tokenTextColor
      }
      console.log(
        chalk.rgb(
          r,
          g,
          b
        )(
          `Token ${token.symbol} on ${
            chainIdToNameMapping[token.chainId]
          } saved`
        )
      )
    } catch (error) {
      console.error(
        chalk.bgRed.white.underline.bold(
          `Error fetching image for token ${token.symbol} on ${
            chainIdToNameMapping[token.chainId]
          }:`
        ),
        error.message
      )
      console.log("at", chalk.blueBright(token.logoURI))
      console.log(
        chalk.grey(
          `Token ${token.symbol} on ${
            chainIdToNameMapping[token.chainId]
          } saved using fallback colors`
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

  await Promise.all([saveColors(colors), saveFailedUrls(failedUrls)])
})()

export function getRgbKeys(color) {
  const [r = 0, g = 0, b = 0] = color.match(/\d+/g)

  return {
    r: Number(r),
    g: Number(g),
    b: Number(b)
  }
}

// Use png instead of webp, as webp is not supported by node canvas
export const getTokenImage = token =>
  `images/migration/png/${getTokenAssetsKey(token)}.png`

export const getChainImage = chain => {
  return chain.chainIconURI.replaceAll("webp", "png")
}

function validateSdkInfo(data) {
  if (!Array.isArray(data.chains) || !Array.isArray(data.tokens)) {
    throw new Error("Invalid Squid data: missing chains or tokens")
  }
}