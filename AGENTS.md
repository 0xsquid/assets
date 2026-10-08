# Agent notes

## Pipeline

- `images/master/<type>/` are the sources for each type in `INCLUDE_FOLDERS` (`scripts/convert.sh`). `yarn convert` writes WebP only, to `images/webp128/<type>/` at 128x128. `images/png128/` is legacy for old widget deployments. Do not add to it.
- `EXTRA_TARGETS` in `scripts/convert.sh` lists other sources, for example the avatars. `yarn convert` writes their WebP to `<dir>/webp/`.
- The "Update tokens" workflow writes `images/migration/webp/` and `scripts/update-tokens/colors.json` daily. Do not add token files by hand.
- `sync-assets.yml` copies `images/`, `squid-brand-assets/` and `colors.json` to Cloudflare R2. It purges the CDN hostname when it replaces or deletes a file. It runs on push to `main` and after the token update.
- Commit the master and the generated outputs together.

## Rules

- Consumers use `https://assets.squidrouter.com`. Never hardcode `raw.githubusercontent.com/0xsquid/assets`.
- Never edit generated WebP files by hand. Regenerate them.
- `yarn test:smoke` runs the update-tokens tests.
