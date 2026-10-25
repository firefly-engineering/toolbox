# Toolbox Blueprint

## System Overview

Toolbox is a self-contained, data-driven Nix package registry for [turnkey](https://github.com/firefly-engineering/turnkey). Each tool lives in `packages/<name>/` as a `data.json` of pinned versions and a thin `default.nix` that hands that data to a builder in `lib/`. The root `flake.nix` assembles every package into a per-system registry. It also derives the flake package outputs, an eval-time registry check and a JSON manifest from that registry. The docs site under `docs/` is generated from the manifest alone. The human-facing overview is [README.md](./README.md), and the contributor guide is [AGENTS.md](./AGENTS.md).

## Local Interface & Invariants

The root holds two source files: `flake.nix` and `justfile`.

- Inputs: `nix-pins` (owns `nixpkgs`), `devenv`, `devenv-root` (a `file+file:///dev/null` placeholder that callers override), `teller`, and `pyproject-nix` / `uv2nix` / `pyproject-build-systems` (used only by `buildUvApplication`).
- `nixConfig` declares the `firefly-toolbox.cachix.org` substituter and its public key for downstream consumers.
- Systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`. `x86_64-darwin` is absent on purpose, because nixpkgs 26.11 dropped it. Some package `data.json` files still carry `x86_64-darwin` hashes, but no flake output builds them.
- Outputs:
  - `registry.<system>.<pkg>`: the stamped `{ versions; default; toolbox; }` entry from `import ./packages/<pkg> { pkgs, lib, toolbox, toolboxLib }`, for every directory under `packages/`.
  - `legacyPackages.<system>.<pkg>.<version_attr | default>`: nested outputs (`nix build .#go.1_25_6`).
  - `packages.<system>`: flat outputs (`<pkg>-<version_attr>`, and a bare `<pkg>` for the default). Both shapes come from `toolboxLib.registryOutputs`.
  - `checks.<system>.registry`: `toolboxLib.checkRegistry`, which forces every advertised system.
  - `manifest`: `toolboxLib.registryManifest` over all systems (`nix eval --json .#manifest`).
  - `overlays.default`: a teller registry overlay.
  - `templates`: `default`/`devshell`, `go` and `rust`.
  - `devShells.<system>.default`: a devenv shell with toolbox's own `beadwork`, `vcs-toolchain`, `just` and `nix`. It also sets `languages.nix.enable` and `languages.python.enable`.
- `toolbox` is a lazy fixed point: packages reference each other through it (`toolbox.go.versions.<v>`), so the dependency graph between packages must stay acyclic.

## Subdirectories & System Boundaries

- lib: [./lib/EGM.md](./lib/EGM.md). `toolboxLib` holds the registry helpers (`readData`, `buildPackage`, `buildToolchain`, `mkStamp`, `registryOutputs`, …) and the per-shape builders (`buildPrebuiltBinary`, `buildRustPackage`, `buildGoPackage`, `buildUvApplication`, `buildSkillBundle`). It also defines the `checkRegistry` gate and the `registryManifest` serialiser.
- packages: [./packages/EGM.md](./packages/EGM.md). 90 registry entries (70 packages, 14 toolchains, 6 skill bundles), each a `default.nix` plus, usually, a `data.json`.
- docs: [./docs/EGM.md](./docs/EGM.md). The `toolbox-docs` Python generator. It turns `nix eval --json .#manifest` into the GitHub Pages site and never reads `packages/*/data.json`.
- templates: [./templates/EGM.md](./templates/EGM.md). Downstream flake templates (`devshell`, `go`, `rust`) that consume `github:firefly-engineering/toolbox`'s public registry output.

## Global Invariants

- Reproducibility: every input is pinned by content hash (`sha256`, `vendorHash`, `cargoHash`, `npmDepsHash`, `pnpmDeps`, lockfiles). No version range is resolved at build time, and upstream's own lockfile is preferred.
- Every registry entry carries a `toolbox` stamp with `kind` set to `package`, `toolchain` or `skill-bundle`. `buildPackage`, `buildToolchain` and `buildSkillBundle` stamp automatically. A hand-built entry (only `packages/solana-toolchain`) must call `mkStamp`.
- `_meta.default` must be a version key. A `builder` field must name a builder. Toolchain component pins and cross-package pins must resolve. Every `patches[].file` must exist. `nix flake check` enforces all four through `checkRegistry`.
- Platform availability is declared with `meta.platforms` and filtered by `availableVersions`. No package hand-builds its outputs to escape it.
- Adding a builder variant never changes the derivations of existing versions. A refactor that preserves behaviour leaves every `drvPath` unchanged.
- The docs generator and the templates consume only published outputs (`.#manifest`, `registry`), never package internals.

## Global Side Effects

- Evaluation is offline, except `buildUvApplication`'s hash-pinned `builtins.fetchTarball` (uv2nix reads `uv.lock` at eval time).
- Builds fetch only through fixed-output derivations: GitHub archives, release assets, PyPI, npm/pnpm/cargo/Go dependency stores.
- CI (`.github/workflows/`): `check.yml` gates `nix flake check`. `cachix.yml` runs on `x86_64-linux` only, so it pushes no aarch64 builds. It runs `nix-fast-build --skip-cached` with `accept-flake-config = true`, and builds and pushes what the `firefly-toolbox` Cachix cache is missing from `packages.<system>` and `devShells.<system>`. `docs.yml` evaluates the manifest, runs the docs tests and publishes `docs/_site`.
- `justfile` recipes `build-packages`, `build-devshell`, `push-packages`, `push-devshell` and `push` build every package and the dev shell, and push both to Cachix.

## System Verification

- Run:

  ```bash
  printf '%s' "$PWD" > .devenv-root
  nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
  ```

- Per package: `nix build --no-link .#<pkg>.default`.
- Docs: `pip install docs/[dev] && pytest docs/tests/ -v`.
- Do not add `--all-systems`. The check derivation is native, and the cross-system coverage comes from evaluation.
