# jjui

## Overview

`jjui`, a TUI for Jujutsu, installed from prebuilt upstream release zips via `toolboxLib.buildPrebuiltBinary`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.jjui`: `versions` = 0.10.2 .. 0.10.11 (6 versions); `default` = `0.10.11` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildPrebuiltBinary { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/jjui` (renamed from `jjui-<version>-<platform>`).
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
- Asset URL: `https://github.com/idursun/jjui/releases/download/v${version}/jjui-${version}-${platform}.zip`.

## Invariants

- `data.json` nests one `{ sha256 }` per system under each version; the hash is the raw `fetchurl` hash of the release asset (no `--unpack`).
- Evaluation throws on a system missing from the `platforms` table; `meta.platforms` is derived from it, so `availableVersions` drops the package elsewhere.
- Asset is a `.zip` unpacked flat (`sourceRoot = "."`); Linux binaries are patched with `autoPatchelfHook`.

## Side Effects

- Fixed-output fetch of the per-system release asset at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#jjui.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
