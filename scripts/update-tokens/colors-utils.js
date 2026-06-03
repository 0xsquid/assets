import { createCanvas, loadImage } from "canvas"
import fs from "fs"
import path from "path"

export const nativeEvmTokenAddress =
  "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

export function isEvmosChain(chain) {
  return chain?.isEvmos || false
}

export function isSolanaSanctumAutomatedToken(token) {
  return (
    token.name.startsWith("Sanctum Automated ") &&
    token.chainId === "solana-mainnet-beta" &&
    /^[a-zA-Z0-9]{5}SOL$/.test(token.symbol)
  )
}

export function getTokenAssetsKey(token) {
  // Remove slashes and colons and lowercase token address
  return `${token?.chainId}_${token?.address
    ?.replace(/[/\:]/g, "")
    .toLowerCase()}`
}

export function getAverageColor(url, { saveHighlight = false } = {}) {
  return new Promise((resolve, reject) => {
    loadImage(url)
      .then(img => {
        const canvas = createCanvas(img.width, img.height)
        const ctx = canvas.getContext("2d")

        if (!ctx) {
          reject(new Error("Canvas context could not be created."))
          return
        }

        canvas.width = img.width
        canvas.height = img.height

        ctx.drawImage(img, 0, 0)

        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
        const data = imageData.data
        const width = canvas.width
        const height = canvas.height

        // Define circle parameters
        const centerX = width / 2
        const centerY = height / 2
        const radius = Math.min(width, height) / 2 // Circle radius
        const innerRadius = radius - 7 // Padding

        let rSum = 0
        let gSum = 0
        let bSum = 0
        let sampledCount = 0

        // Process pixels and highlight relevant parts
        for (let y = 0; y < height; y++) {
          for (let x = 0; x < width; x++) {
            // Calculate distance from the center
            const dx = x - centerX
            const dy = y - centerY
            const distance = Math.sqrt(dx * dx + dy * dy)

            // Check if the pixel is within the circular border
            if (distance >= innerRadius && distance <= radius) {
              const index = (y * width + x) * 4 // Get pixel index

              // Fully transparent pixels carry no visible color (the canvas
              // reports them as 0,0,0), so they are excluded from the average.
              if (data[index + 3] === 0) {
                continue
              }

              rSum += data[index]
              gSum += data[index + 1]
              bSum += data[index + 2]
              sampledCount++

              // Highlight the pixel in red
              data[index] = 255 // Red
              data[index + 1] = 0 // Green
              data[index + 2] = 0 // Blue
              data[index + 3] = 255 // Alpha (fully opaque)
            }
          }
        }

        // Apply the updated image data to the canvas
        ctx.putImageData(imageData, 0, 0)

        if (saveHighlight) {
          const fileName = url
            .split("/")
            .pop()
            .split("?")[0]
            .replace(/\.[^/.]+$/, "") // Extract file name without extension
          const outputDir = path.join("images", "highlighted-area")

          // Create the directory if it doesn't exist
          if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true })
          }

          const outputPath = path.join(outputDir, `${fileName}.png`)
          const out = fs.createWriteStream(outputPath)
          const stream = canvas.createPNGStream()
          stream.pipe(out)
          out.on("finish", () => {
            console.log(`Highlighted image saved to ${outputPath}`)
          })
        }

        if (sampledCount === 0) {
          reject(
            new Error(
              "No opaque pixels sampled — image may be empty, fully transparent, or smaller than the sampling ring."
            )
          )
          return
        }

        // Represent the icon by the mean of its opaque edge pixels, so a shaded
        // or gradient body resolves to its average color.
        const r = Math.round(rSum / sampledCount)
        const g = Math.round(gSum / sampledCount)
        const b = Math.round(bSum / sampledCount)

        resolve(`rgb(${r},${g},${b})`)
      })
      .catch(err => reject(err))
  })
}

export function getContrastColor({ r, g, b }) {
  const brightness = (r * 299 + g * 587 + b * 114) / 1000

  return brightness >= 190 ? "#000" : "#fff"
}
