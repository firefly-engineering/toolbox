# python

## Overview

CPython from astral-sh `python-build-standalone` (`install_only_stripped`) tarballs; a custom `mkDerivation` installing the whole interpreter tree.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.python`: `versions` = 3.13.12, 3.13.14, 3.13.15; `default` = `3.13.15`.
- Asset URL: `https://github.com/astral-sh/python-build-standalone/releases/download/${release}/cpython-${version}+${release}-${targetTriple}-install_only_stripped.tar.gz`.
- Installs the unpacked tree (`bin/python3`, `lib/`, ...) into `$out`.
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.

## Invariants

- Each version entry carries `release` (the python-build-standalone release date tag) and `{ sha256 }` per system (raw `fetchurl` hash).
- `_meta.release` exists but the builder reads `versionData.release`, so every version must set its own.
- `dontFixup`; Linux binaries are patched with `autoPatchelfHook` against `cc.cc.lib` and `zlib`.
- Known defect: `dontFixup = true` skips the fixup phase, where `autoPatchelfHook` runs, so Linux binaries ship unpatched and the hook and its inputs have no effect.

## Side Effects

- Fixed-output fetch of the per-system tarball at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#python.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
