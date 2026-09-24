# Squid Assets

Token, chain, wallet and provider images for Squid front ends.

## Local setup

1. Install system dependencies (`librsvg`, `webp`, `imagemagick`, `jq`, `wget`, `ffmpeg`):

   ```bash
   yarn setup:macos   # macOS
   yarn setup:linux   # Linux
   ```

2. Install Node dependencies (Yarn 1, pinned with `packageManager`):

   ```bash
   yarn install
   ```

3. Only for `yarn update-tokens` and `yarn update-colors`: create a `.env` file in the repo root with credentials from the team.

   ```
   SQUID_API_URL=
   SQUID_INTEGRATOR_ID=
   ```

To add chains, wallets or providers, you need only step 1 and `yarn convert`.

## How the pipeline works

### Chains, wallets and providers (manual)

A designer or developer drops the source image into `images/master/<type>/`. `yarn convert` renders it to `images/png128/<type>/` and `images/webp128/<type>/` at 128x128. The master and the generated outputs are committed together in a PR.

```
images/master/<type>/<name>.svg  ──yarn convert──▶  images/png128/<type>/<name>.png + images/webp128/<type>/<name>.webp
```

`yarn convert` only processes `chains`, `wallets` and `providers`. It skips outputs that already exist.

### Tokens (automated)

The Squid API `/v2/sdk-info` exposes a `logoURI` per token. The "Update tokens" GitHub workflow runs `yarn update-tokens` daily at 00:00 UTC. It downloads the missing images, resizes them to 128x128 and writes `images/migration/webp/<chainId>_<address>.webp`. It computes `bgColor` and `textColor` into `scripts/update-tokens/colors.json`. It commits the result with the message `chore: update tokens [skip ci]`.

```
Squid API logoURI  ──daily workflow──▶  images/migration/webp/<chainId>_<address>.webp + colors.json
```

Do not add token files by hand. If you need to fix a token image, see [Fix or refresh a token image](#fix-or-refresh-a-token-image).

## Conventions

### Shape

Chains, wallets and providers: square, full canvas, no rounded corners, solid brand background, glyph centered with some padding. Tokens: rounded or circular. Front ends require these shapes.

Backgrounds must be one solid flat color. Do not use gradients. `yarn update-colors` computes `bgColor` as the average color of the image for each chain and token, and a gradient gives a wrong or muddy color.

### Format and quality

The master is the official SVG whenever it exists, so we keep the highest quality. Use a PNG master only when no SVG exists. Outputs are always 128x128 PNG and WebP. Never edit files in `png128` or `webp128` by hand. Regenerate them.

### Naming

Chain, wallet and provider file name = the Squid API identifier, lowercase, with the `.svg` extension. Examples:

- `images/master/chains/arbitrum.svg`
- `images/master/providers/uniswap.svg`
- `images/master/wallets/metamask.svg`

Token file name = `<chainId>_<address>.webp`. The address is lowercase, with `/` and `:` removed.

### Legacy folders

These folders exist for old consumers. Do not add new work there. `yarn convert` does not process them.

- `images/tokens/`
- `images/chainIcons/`
- `images/stocks/`
- `images/master/tokens/`
- `images/master/onramps/`

## How to

### Add a chain, wallet or provider image

1. Get the official SVG. Use a PNG only when no SVG exists.
2. Apply the [shape convention](#shape).
3. Name the file after the Squid API identifier (see [Naming](#naming)).
4. Drop it in `images/master/<type>/`.
5. Run `yarn convert`. It writes `images/png128/<type>/<name>.png` and `images/webp128/<type>/<name>.webp`. It needs only the system dependencies from [Local setup](#local-setup). It does not need a `.env` file.
6. To replace an existing icon, delete the old files in `png128` and `webp128` first. Then run `yarn convert` again.
7. Commit the master together with the generated PNG and WebP files. Open a PR.

### Fix or refresh a token image

1. Fix the token `logoURI` upstream in the Squid API or backend.
2. Wait for the daily run, or dispatch the "Update tokens" workflow with the `tokens` input. See [Automation](#automation).

## Scripts

### `yarn update-tokens`

Refreshes tokens from the Squid API in three steps:

1. Fetch tokens from `/v2/sdk-info`. List the images missing from `images/migration/webp`. Skip URLs recorded in `url_fetch_errors.json`.
2. Download each new image. Resize it to 128x128. Write it to `images/migration/webp/<chainId>_<address>.webp`. Accepts SVG, PNG, JPEG, GIF (animated WebP), WebP and AVIF.
3. Run `yarn update-colors`.

### `yarn update-colors`

Recomputes colors without downloads:

1. Converts WebPs in `images/migration/webp` to PNGs in `images/migration/png`. The `canvas` library cannot read WebP.
2. Computes `bgColor` (average) and `textColor` (contrast) for each chain and token. Saves them to `scripts/update-tokens/colors.json`. Records failed URLs in `scripts/update-tokens/url_fetch_errors.json`. Skips entries that already have a `bgColor`.

Needs `SQUID_API_URL` and `SQUID_INTEGRATOR_ID`.

### `yarn convert [--size=N]`

Converts SVGs and resizes PNGs under `images/master/{chains,wallets,providers}`. Writes to `images/png<SIZE>/` and `images/webp<SIZE>/`. Default size is 128. Skips outputs that already exist.

## Automation

The GitHub Actions workflow is `.github/workflows/update-tokens.yml`. It commits `images/migration/webp` and `scripts/update-tokens/colors.json` to `main`.

You can start it manually from the Actions tab ("Run workflow"). The optional `tokens` input takes `<chainId>_<address>` keys, separated by spaces or commas. The workflow removes those images before the run so they are fetched again. If no replacement is created, it restores the previous file. Leave the input empty for a normal full update.

The repo Variables `SQUID_API_URL` and `SQUID_INTEGRATOR_ID` must be set (Settings > Secrets and variables > Actions > Variables).

## Folder structure

```
.
├── package.json
├── images
│   ├── master                      # sources for `yarn convert`
│   │   ├── chains/
│   │   ├── wallets/
│   │   ├── providers/
│   │   ├── onramps/                # legacy
│   │   └── tokens/                 # legacy
│   ├── png128/                     # `yarn convert` output (chains, wallets, providers)
│   ├── webp128/                    # `yarn convert` output (chains, wallets, providers)
│   ├── migration
│   │   ├── webp/                   # `yarn update-tokens` output, committed
│   │   └── png/                    # intermediate PNGs for colors, gitignored
│   ├── tokens/                     # legacy
│   ├── chainIcons/                 # legacy
│   └── stocks/                     # legacy
└── scripts
    ├── convert.sh
    ├── smoke-test/
    └── update-tokens/
        ├── fetch-new-tokens.js      # entry: queues missing webps
        ├── save-new-tokens.sh       # downloads and converts queued images
        ├── convert-webp-to-png.sh   # webp to png for node-canvas
        ├── colors.js                # entry: extracts bgColor / textColor
        ├── squid-api.js             # Squid /v2/sdk-info client
        ├── colors-utils.js          # color math and token key helpers
        ├── assert-entry.js          # guard against importing entry scripts
        ├── colors.json              # generated, committed
        └── url_fetch_errors.json    # generated, gitignored
```
