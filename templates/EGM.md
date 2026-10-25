# templates

## Overview

Flake templates for downstream consumers of the toolbox registry. Each one is a
standalone flake: a `flake.nix` that builds `devShells.<system>.default` from
`toolbox.registry.<system>`, plus an `.envrc` (`use flake`). The `templates`
output in the root `flake.nix` registers them:

| Template name         | Path                   |
| --------------------- | ---------------------- |
| `default`, `devshell` | `./templates/devshell` |
| `go`                  | `./templates/go`       |
| `rust`                | `./templates/rust`     |

The template directories carry no contract file of their own on purpose.
`nix flake init` copies every tracked file in a template directory into the
consumer's project, so a contract placed there would ship downstream. This
file documents all three templates instead.

## Interface

- Common to all three `flake.nix` files:
  - inputs `nix-pins`, `nixpkgs` (follows `nix-pins/nixpkgs`) and `toolbox`
    (`github:firefly-engineering/toolbox`; its `nix-pins` follows the
    consumer's);
  - output `devShells.<system>.default`, a `pkgs.mkShell` for a hard-coded
    `systems` list (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`,
    `aarch64-darwin`);
  - `.envrc`: `use flake`, so direnv loads the default shell.
- `devshell/`:
  - local helper `tool name` returns
    `reg.${name}.versions.${reg.${name}.default}`, the package's default
    version;
  - ships `(tool "jq")` only. Commented examples show `go-toolchain`,
    `rust-toolchain`, `python-toolchain`, `js-toolchain` and an exact pin
    (`reg.go.versions."<version>"`).
- `go/`:
  - packages the default `go-toolchain` (today version `7`: go, gopls,
    golangci-lint, gotestsum, go-licenses). The inline comment lists only the
    first three;
  - sets `env.GOROOT = "${go}/share/go"`, where `go` is the default version of
    the `go` package.
- `rust/`:
  - packages the default `rust-toolchain` (today version `5`: rust,
    rust-analyzer, cargo-edit);
  - sets `env.RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust/library"`, where
    `rust` is the default version of the `rust` package.

## Invariants

- The templates read only the public registry output
  (`registry.<system>.<pkg>.{versions,default}`), never `packages/*/data.json`.
  Bumping a package's `_meta.default` changes what new consumers get.
- Every name passed to `tool` must be a toolbox package, or evaluation fails.
- The hard-coded `systems` list includes `x86_64-darwin`, which the toolbox
  flake no longer advertises. The registry has no entry for that system, so
  the shell fails to evaluate there.
- `GOROOT` comes from `reg.go.default` and `RUST_SRC_PATH` from
  `reg.rust.default`, not from the toolchain's own pin. Each pair only agrees
  while the toolchain default pins the package default (today go `1.27.2` and
  rust `1.98.1`). Bump them in step.
- The toolbox `go` derivation must keep its tree at `share/go`. The `rust`
  derivation must ship the std sources at `lib/rustlib/src/rust/library`,
  because rust-analyzer reads them from there.
- Known defect: `packages/rust` installs no `rust-src` component, so
  `RUST_SRC_PATH` points to a path that does not exist.
- Template directories hold only files meant for consumers. Do not add
  `EGM.md` or other repo documentation inside them.

## Side Effects

- None when the flakes are evaluated. Using a template fetches the `nix-pins`
  and `toolbox` inputs and writes `flake.lock` in the consumer's project.
- Entering the `go` or `rust` shell exports `GOROOT` or `RUST_SRC_PATH`.

## Verification

- Run in an empty temp dir: `nix flake init -t <toolbox>#<name>`, then
  `nix develop -c jq --version` (devshell), `nix develop -c go version` (go)
  or `nix develop -c cargo --version` (rust).
- `nix flake check` at the repo root checks only the shape of the `templates`
  output. It does not evaluate the template flakes.
