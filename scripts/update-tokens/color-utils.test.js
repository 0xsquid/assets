import { describe, it } from "node:test"
import assert from "node:assert"
import { createCanvas } from "canvas"

import { getAverageColor } from "./colors-utils.js"

// getAverageColor samples a 7px-wide ring at the outer edge of the image and
// derives a representative color from it. These tests build synthetic 128x128
// PNGs in memory (no dependency on the gitignored images/migration/png folder)
// so the behavior is deterministic and the bug scenarios are explicit.

const SIZE = 128
const CENTER = SIZE / 2

// Build a PNG buffer by setting every pixel via a (x,y) -> [r,g,b,a] function.
// PNG round-trips RGBA losslessly, so sampled pixels match exactly.
function makePng(pixelFn) {
  const canvas = createCanvas(SIZE, SIZE)
  const ctx = canvas.getContext("2d")
  const imageData = ctx.createImageData(SIZE, SIZE)
  const data = imageData.data

  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      const i = (y * SIZE + x) * 4
      const [r, g, b, a] = pixelFn(x, y)
      data[i] = r
      data[i + 1] = g
      data[i + 2] = b
      data[i + 3] = a
    }
  }

  ctx.putImageData(imageData, 0, 0)
  return canvas.toBuffer("image/png")
}

const distFromCenter = (x, y) => Math.hypot(x - CENTER, y - CENTER)
const parseRgb = str => str.match(/\d+/g).map(Number)

describe("getAverageColor", () => {
  it("returns a color close to a solid opaque icon", async () => {
    const png = makePng(() => [80, 160, 40, 255])

    const [r, g, b] = parseRgb(await getAverageColor(png))

    assert.ok(Math.abs(r - 80) <= 5, `r=${r}`)
    assert.ok(Math.abs(g - 160) <= 5, `g=${g}`)
    assert.ok(Math.abs(b - 40) <= 5, `b=${b}`)
  })

  it("ignores transparent background pixels instead of reading them as black", async () => {
    // Green disc (radius 60) with a gradient body on a transparent canvas.
    // The sampling ring (radius 57-64) straddles the disc edge: its inner band
    // is green, its outer band transparent. Transparent pixels read as (0,0,0),
    // so the result must come from the green body, not the transparent rim.
    const png = makePng((x, y) => {
      if (distFromCenter(x, y) <= 60) {
        return [30, 120 + (y % 32), 40, 255]
      }
      return [0, 0, 0, 0]
    })

    const [r, g, b] = parseRgb(await getAverageColor(png))

    assert.ok(g > r && g > b, `expected green-dominant, got rgb(${r},${g},${b})`)
    assert.ok(g > 100, `expected strong green, got g=${g}`)
    assert.ok(!(r === 0 && g === 0 && b === 0), "result must not be black")
  })

  it("represents the gradient body, not a small flat region", async () => {
    // Fully opaque image: most of the ring is a green gradient (many distinct
    // shades), with a small wedge of flat red. The averaged result must reflect
    // the dominant green area, not the minority flat-red wedge.
    const png = makePng((x, y) => {
      const d = distFromCenter(x, y)
      const inRing = d >= 57 && d <= 64
      if (inRing && x >= 92 && x <= 100) {
        return [220, 0, 0, 255]
      }
      return [30, 120 + (x % 48), 40, 255]
    })

    const [r, g, b] = parseRgb(await getAverageColor(png))

    assert.ok(g > r && g > b, `expected green-dominant, got rgb(${r},${g},${b})`)
  })

  it("rejects when the sampled ring has no opaque pixels", async () => {
    const png = makePng(() => [0, 0, 0, 0])

    await assert.rejects(() => getAverageColor(png))
  })
})
