# Squid Assets

Token and chain images for front ends built with the Squid SDK

## Scripts

### Convert

Convert all SVGs in `/images/master` to 128x128 PNGs and WebPs in `/images/png128` and `/images/webp128` by default.

```bash
yarn convert
```

You can specify a different size by passing the `--size` argument:

The following command will create 500x500 PNGs and WebPs in `/images/png500` and `/images/webp500` respectively.

```bash
yarn convert --size=500
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
