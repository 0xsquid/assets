# Squid Assets

Token and chain images for front ends built with the Squid SDK

## Scripts

### Convert

Convert all SVGs in `/images/master` to PNGs and WebPs in `/images/png` and `/images/webp` respectively.

```bash
yarn convert
```

Override existing files in png and webp folders:

```bash
yarn convert --override
```

### Compare

Compare folders size

```bash
yarn compare
```

## Install rsvg-convert and cwebp

Mac:

```bash
brew install librsvg webp
```

Linux:

```bash
sudo apt-get update
sudo apt-get install librsvg2-bin webp
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
