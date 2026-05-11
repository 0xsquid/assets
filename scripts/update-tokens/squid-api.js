import "dotenv/config"
import chalk from "chalk"
import {
  isEvmosChain,
  isSolanaSanctumAutomatedToken,
  nativeEvmTokenAddress
} from "./colors-utils.js"

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

function validateSdkInfo(data) {
  if (!Array.isArray(data.chains) || !Array.isArray(data.tokens)) {
    throw new Error("Invalid Squid data: missing chains or tokens")
  }
}

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
