# pytest

## Overview

pytest at a pinned PyPI version, built by overriding nixpkgs' `python3Packages.pytest` source; a custom `runCommand` exposing its entry points.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.pytest`: `versions` = 9.0.3, 9.1.1; `default` = `9.1.1`.
- Builder: custom `builders.default` using `pythonPkgs.pytest.overridePythonAttrs` with `src = pkgs.fetchPypi { pname = "pytest"; inherit version; hash = versionData.sha256; }`.
- Installs `bin/pytest` and `bin/py.test` as symlinks into the overridden pytest.

## Invariants

- Each version entry carries only `sha256`, the `fetchPypi` sdist hash.
- Interpreter and pytest's own dependencies come from the pinned nixpkgs `python3Packages`, not from [python](../python/EGM.md).

## Side Effects

- Fixed-output fetch of the PyPI sdist at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#pytest.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
