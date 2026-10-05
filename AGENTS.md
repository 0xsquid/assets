# Agent notes

## Pipeline

- `images/master/{chains,wallets,providers,cash}/` are the sources. `yarn convert` writes WebP only, to `images/webp128/` at 128x128. `images/png128/` is legacy for old widget deployments. Do not add to it.
- `squid-brand-assets/pfps/*.svg` are the avatar sources. `yarn convert` writes `squid-brand-assets/pfps/webp/` at 256x256.
- The "Update tokens" workflow writes `images/migration/webp/` and `scripts/update-tokens/colors.json` daily. Do not add token files by hand.
- `sync-assets.yml` copies `images/`, `squid-brand-assets/` and `colors.json` to Cloudflare R2 and purges changed URLs. It runs on push to `main` and after the token update.
- Commit the master and the generated outputs together.

## Rules

- Consumers use `https://assets.squidrouter.com`. Never hardcode `raw.githubusercontent.com/0xsquid/assets`.
- Never edit `webp128` or `pfps/webp` by hand. Regenerate them.
- Tests: `yarn test:smoke`. See `README.md` for details.
