# qmd

## Overview

Packages [qmd](https://github.com/tobi/qmd) (Query Markup Documents: on-device hybrid BM25/vector/LLM-rerank search over markdown), a Bun/TypeScript application, built from the tagged GitHub source. Adapted from upstream's own `flake.nix`: a fixed-output `node_modules` derivation (`bun install --frozen-lockfile`) feeds a main build that compiles the `better-sqlite3` native addon with `node-gyp` and wraps `bun src/cli/qmd.ts`.

## Interface

- `default.nix`: custom `builders.default` (two `mkDerivation`s: `qmd-node-modules` FOD + `qmd`) passed to `toolboxLib.buildPackage { name = "qmd"; }`.
- `data.json`: versions `2.8.3` (`_meta.default`), `2.5.3`.
- Output: `$out/bin/qmd` (a `makeWrapper` around toolbox bun running `$out/lib/qmd/src/cli/qmd.ts`, with `DYLD_LIBRARY_PATH`/`LD_LIBRARY_PATH` set to nixpkgs `sqlite`); `$out/lib/qmd/{node_modules,src,skills,package.json}`.
- Cross-package deps: `toolbox.bun.versions.<bun>`, or `toolbox."bun-baseline".versions.<bun>` on x86_64 when that version exists ([bun](../bun/EGM.md), [bun-baseline](../bun-baseline/EGM.md)).
- Platforms: `meta.platforms` is set per version to exactly the systems keyed in that version's `nodeModules`. `2.8.3` has `aarch64-darwin`, `aarch64-linux` and `x86_64-linux`; `2.5.3` has only `aarch64-darwin` and `x86_64-linux`. No version has `x86_64-darwin`.

## Invariants

- Each version entry needs `sha256` (`fetchFromGitHub` `--unpack` hash of tag `v<version>`), `bun` (a toolbox bun version) and `nodeModules.<system>` (per-system recursive hash of the `node_modules` FOD; content differs per platform).
- Dependencies come from upstream's committed bun lockfile via `--frozen-lockfile`; the build fails rather than re-resolving.
- On x86_64 the AVX2-free `bun-baseline` build is used unconditionally when available, so builds/caches made on modern hosts do not SIGILL on pre-Haswell CPUs (both at `bun install` time and at runtime).
- The main build's native inputs are toolbox bun, `makeWrapper`, `nodejs`, `node-gyp` and `python3`; its build input is `sqlite`.
- Darwin needs `cctools` and `xcbuild` for `node-gyp`.

## Side Effects

- Build time only: fixed-output fetch of the GitHub source and the `bun install` FOD (network, proxy env vars passed through as `impureEnvVars`). No runtime network access added by the package.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#qmd.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
