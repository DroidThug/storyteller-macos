# MLX alignment on macOS

Storyteller can align audio to text with CTC emissions computed on the Apple GPU through MLX.
This is only available natively on Apple Silicon.

## What you need, and where it comes from

| Piece | Where it comes from | Where it ends up |
|---|---|---|
| MLX addon (`@storyteller-platform+mlx-audio.node`) | upstream's Git LFS, at the pinned commit | `<standalone>/prebuilds/darwin-arm64/` |
| Metal shader library (`mlx.metallib`) | same (upstream fetches it from the official `ml-explore/mlx-swift` release) | same folder, next to the addon |
| Align addon | upstream's Git LFS | `<standalone>/work-dist/@storyteller-platform/align/prebuilds/darwin-arm64/` |
| Model weights (QuartzNet, about 200 MB) | `scripts/install-models.sh` (downloads from upstream's model registry) | `~/Library/Application Support/ghost-story/models/` |

`setup.sh` pulls the LFS files, `build.sh` copies them into place, and `run.sh` re-copies the MLX
files without overwriting. None of them are stored in this repo.

Why the copy step exists: upstream's Dockerfile only copies the Linux prebuilds, and there are no
Linux MLX files. Without the copy, alignment fails with:
`MLX Metal shader library not found next to the native binding`.

## Using it

1. `./scripts/install-models.sh` (or `SKIP_WHISPER=1 ./scripts/install-models.sh` for CTC only).
2. Start the server and open the book in the web UI.
3. Start read-aloud processing and choose the **CTC** option with the **MLX** device, not Whisper.
4. Pick another language with `CTC_LANGUAGE=<code>` in `config.env` before installing models.
   Languages QuartzNet does not cover fall back to a larger multilingual model.

## Troubleshooting

- **"MLX Metal shader library not found"**: the prebuilds are missing from
  `<standalone>/prebuilds/darwin-arm64/`. Re-run `./scripts/build.sh --assemble-only`.
- **Stale files after changing `UPSTREAM_REF`**: `run.sh` uses `cp -n`, so it never replaces an
  existing copy. Re-run `build.sh --assemble-only` after a bump.
- **Out of memory or heavy swapping on 8 GB Macs**: close other apps, and expect long audiobooks to
  swap. Keep other work off the machine while a book is processing.
- **Check the addon loads at all**: `node -e "process.dlopen({exports:{}}, process.argv[1])" <path-to>.node`.

## Not covered here

Rebuilding the addon from source (`yarn workspace @storyteller-platform/mlx-audio build:native`) and
re-fetching the metallib (`build:native:metallib`) are upstream's scripts. They are not exercised by
these scripts or by CI, and building the addon needs a Swift toolchain.
