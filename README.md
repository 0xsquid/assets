# Squid Assets

Token and chain images for front ends built with the Squid SDK

## Scripts

Token images are stored in the `images/migration/webp` folder.
File names in this folder follow the format `<chainId>_<tokenAddress.toLowerCase().replaceAll("/", "")>.webp`.

To update token images, run:

```sh
yarn update-tokens
```

This script will:

1. fetch all tokens from Squid API
2. Download and save every token image (unless it already exists in `images/migration/webp`)
3. Save new token colors to `scripts/update-tokens/colors.json` (previous conversion to png is needed because of a limitation in the canvas library and webp)

## Install rsvg-convert, cwebp, and imagemagick

Mac:

```bash
yarn setup:macos
```

Linux:

```bash
yarn setup:linux
```

## Folder Structure

```
.
├── package.json
├── images
│   ├── master
│   │   ├── chains
│   │   │   └── ethereum.svg
│   │   ├── tokens
│   │   │   └── eth.svg
│   │   └── wallets
│   │       └── metamask.svg
│   ├── png
│   │   ├── chains
│   │   │   └── ethereum.png
│   │   ├── tokens
│   │   │   └── eth.png
│   │   └── wallets
│   │       └── metamask.png
├   └── webp
│       ├── chains
│       │   └── ethereum.webp
│       ├── tokens
│       │   └── eth.webp
│       └── wallets
│           └── metamask.webp
└── scripts
    └── convert.sh
```
