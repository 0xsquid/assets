# Squid Assets

Token and chain images for front ends built with the Squid SDK

## First-time setup

1. Install system dependencies (`librsvg`, `webp`, `imagemagick`, `jq`, `wget`, `ffmpeg`):

   ```bash
   yarn setup:macos   # macOS
   yarn setup:linux   # Linux
   ```

2. Install Node dependencies (uses Yarn 1, pinned via `packageManager`):

   ```bash
   yarn install
   ```

3. Create a `.env` file in the repo root with credentials from the team:

   ```
   SQUID_API_URL=
   SQUID_INTEGRATOR_ID=
   ```

   These are required by `yarn update-tokens` to call the Squid API.

## Scripts

### `yarn update-tokens`

Refreshes tokens from the Squid API. Runs three steps:

1. Fetch tokens from Squid (`/v2/sdk-info`) and list anything missing from `images/migration/webp` (skipping previously failed URLs in `url_fetch_errors.json`).
2. Download each new image, resize to 128×128, and write it to `images/migration/webp/<chainId>_<tokenAddress>.webp`. Handles SVG, PNG/JPEG, GIF (animated WebP), WebP, and AVIF inputs.
3. Run `yarn update-colors` (see below).

Token file names follow `<chainId>_<tokenAddress.toLowerCase().replace(/[/\:]/g, "")>.webp`.

### `yarn update-colors`

Recomputes colors without downloading new images:

1. Converts WebPs in `images/migration/webp` to PNGs in `images/migration/png` (the `canvas` lib used next doesn't read WebP).
2. For each chain and token, computes `bgColor` (average) and `textColor` (contrast) and saves them to `scripts/update-tokens/colors.json`. Failed URLs are recorded in `scripts/update-tokens/url_fetch_errors.json`. Entries that already have a non-empty `bgColor` are skipped.

Also requires `SQUID_API_URL` and `SQUID_INTEGRATOR_ID`.

### `yarn convert [--size=N]`

Converts SVGs (and resizes PNGs) under `images/master/{chains,wallets,providers}` into `images/png<SIZE>/...` and `images/webp<SIZE>/...`. Default size is 128. Other master folders (`tokens`, `onramps`) are not processed by this script.

### `yarn compare`

Prints `du -sh` for every subfolder under `images/`. Read-only.

### `yarn test:colors`

Unit tests for the color utility helpers. No network, no file writes.

## Folder Structure

```
.
├── package.json
├── images
│   ├── master                      # source SVGs (input to `yarn convert`)
│   │   ├── chains/
│   │   ├── wallets/
│   │   ├── providers/
│   │   ├── onramps/
│   │   └── tokens/
│   ├── png128/                     # output of `yarn convert` (size suffix matches --size)
│   ├── webp128/
│   └── migration
│       ├── webp/                   # `yarn update-tokens` output — e.g. 1_0x...0.webp
│       └── png/                    # intermediate PNGs for color extraction
└── scripts
    ├── convert.sh
    ├── compare_folders_size.sh
    └── update-tokens/
        ├── fetch-new-tokens.js
        ├── save-new-tokens.sh
        ├── convert-webp-to-png.sh
        ├── colors.js
        ├── colors.json             # generated: bgColor / textColor per chain & token
        └── url_fetch_errors.json   # generated: URLs that failed during fetch
```
