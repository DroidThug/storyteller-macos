# storyteller-macos

Run [Storyteller](https://gitlab.com/storyteller-platform/storyteller) natively on Apple Silicon, without Docker.

This repo does **not** contain Storyteller. It holds the scripts that fetch a pinned upstream
commit, build it for macOS, and start it. Storyteller's own code stays on GitLab.

Upstream's own docs say Docker on a Mac cannot access the GPU, so the Apple-only paths (MLX
alignment, CoreML whisper) cannot run inside the container. The Docker answer on a Mac is to run
`ghost-story serve` natively on the host and point the containerized Storyteller at it ("On Another
Server"). This repo takes the other route: the whole server runs natively, with no container and no
offload step.

### If you would rather keep Storyteller in Docker

Run only the GPU-heavy part natively: `npx @storyteller-platform/ghost-story@latest serve --api-key <key>`,
then in Storyteller's settings choose "On Another Server" and enter the URL and key. From inside the
container the host is `host.docker.internal`. The
[offloading guide](https://storyteller-platform.dev/docs/tutorials/offloading-transcription) documents
the older `ghost-story server` (whisper only) and is **out of date for the v3 beta**. `serve` is the
beta command; we have not tested it here.

## Requirements

- Apple Silicon Mac (the MLX and CoreML prebuilds are `darwin-arm64` only)
- [Homebrew](https://brew.sh) and Xcode command line tools
- Roughly 10 GB of free disk for source, build output and models

## Prebuilt releases (no local build)

CI can build the pinned upstream version for you: run the **release** workflow (Actions tab). It builds,
packs, boots the archive from a different folder to prove it is self-contained, and attaches it to a
**draft** GitHub Release (tick "publish" to skip the draft).

```sh
./scripts/install-release.sh        # latest published release; verifies the sha256
./scripts/install-models.sh
./scripts/run.sh
```

## Quick start (build it yourself)

```sh
./scripts/setup.sh           # tools, pinned source checkout, the LFS files it needs, readium
./scripts/build.sh           # yarn install + production build (slow; BUILD_NICE=19 to be gentle)
./scripts/install-models.sh  # whisper.cpp (CoreML) + QuartzNet (MLX); SKIP_WHISPER=1 / SKIP_CTC=1
./scripts/run.sh             # http://127.0.0.1:8001
```

Configuration is environment variables on `run.sh`: `STORYTELLER_DATA_DIR` (default `./data`),
`PORT`, `READIUM_PORT`, `HOSTNAME_BIND`. A secret key is generated into the data dir on first run.
If the data dir is under `/Volumes/...` and that volume is not actually mounted (a leftover folder
with the same name does not count), `run.sh` refuses to start instead of writing to your internal disk.

`launchd/dev.storyteller-macos.plist.template` is a LaunchAgent starting point.

## What is pinned

`config.env` holds the upstream commit (`UPSTREAM_REF`), Node major and model choices. The readium
version is read from upstream's Dockerfile at that commit (override with `READIUM_VERSION`), so it
moves with upstream. Upstream's Nix dev environment pins a different, older readium (0.6.5); we follow
the Dockerfile, which is its production path. Nothing is built from a moving target.

## Tracking upstream

- `.github/workflows/upstream-watch.yml` runs weekly, compares `UPSTREAM_BASE_TAG` with upstream's
  newest `web-v*` tag, and opens an issue when there is a newer one.
- To move forward: bump `UPSTREAM_REF` and `UPSTREAM_BASE_TAG`, push, and let CI rebuild.
- `./scripts/check-upstream.sh` shows the same comparison locally.

## CI

`.github/workflows/ci.yml` runs on a free `macos-14` (Apple silicon) runner. It sets up, builds,
and smoke-tests (`scripts/smoke.sh`: boots the server, checks `/login`, migrations, readium).
It also runs upstream's test suites, currently **non-blocking** until a green baseline exists.

## MLX

See [docs/MLX.md](docs/MLX.md) for what the MLX files are, where they come from, how to use CTC with
MLX in the UI, and troubleshooting.

## Known gaps

Upstream's Dockerfile only copies the Linux native prebuilds. For macOS, `build.sh` additionally
copies the `darwin-arm64` align prebuild and the MLX addon plus `mlx.metallib`; without those the
alignment step fails with "MLX Metal shader library not found". This is a packaging gap upstream
that is worth fixing there.

Status: CI runs `setup.sh`, `build.sh` and `smoke.sh` from a fresh checkout on a macOS arm64 runner, and
upstream's test suites (all passing on the pinned commit). CI does not run MLX or whisper alignment, because
that needs models and audio; those paths were verified by hand on one machine (Apple M2, 8 GB). Installing
models through `npx` (used when there is no local build, i.e. with a prebuilt release) is untested.

## Licenses

Scripts in this repo: MIT. Storyteller is MIT at the repository root, but some of its packages
carry their own license (for example `ghost-story` is GPL-3.0). The repo itself does not contain
upstream code. GitHub Releases here do contain a build of it; each archive ships `NOTICE.md`, `licenses/` and
`build-info.json` pointing at the exact upstream commit, which is the corresponding source.
