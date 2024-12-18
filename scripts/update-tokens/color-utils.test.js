import { describe, it } from "node:test"

import { getAverageColor } from "./colors-utils.js"
import assert from "node:assert"

describe("getAverageColor", () => {
  it("returns the correct average color for predefined images", async () => {
    const colorA = await getAverageColor(
      "images/migration/png/solana-mainnet-beta_7i5KKsX2weiTkry7jA4ZwSuXGhs5eJBEjY8vVxR4pfRx.png"
    )

    console.log({ colorA })

    assert.strictEqual(colorA, "rgb(228,189,123)")

    const colorB = await getAverageColor(
      "images/migration/png/solana-mainnet-beta_BNso1VUJnh4zcfpZa6986Ea66P6TCp59hvtNJ8b1X85.png"
    )

    assert.strictEqual(colorB, "rgb(238,186,12)")

    const colorC = await getAverageColor(
      "images/migration/png/solana-mainnet-beta_9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E.png"
    )

    assert.strictEqual(colorC, "rgb(249,169,71)")
  })

  it("returns the correct average color for a gradient image", async () => {
    const colorA = await getAverageColor(
      "images/migration/png/solana-mainnet-beta_J9nsngni1Pavf4ijP4R9QBaD1yEzKzzUQ1vVgcDQT18J.png"
    )

    assert.strictEqual(colorA, "rgb(149,49,206)")
  })
})
