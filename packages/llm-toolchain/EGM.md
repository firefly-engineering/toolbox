# llm-toolchain

## Overview

LLM/agent toolchain (CLIs, MCP servers and Claude Code skill bundles) assembled with `toolboxLib.buildToolchain`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.llm-toolchain` (stamp `kind = "toolchain"`, `components` per version): `versions` = 1 .. 9; `default` = `9`.
- Builder: `toolboxLib.buildToolchain { inherit toolbox pkgs; name = "llm-toolchain"; dataPath = ./data.json; }`; no custom Nix logic.
- Default composition: `qmd` 2.8.3, `openspec` 1.6.0, `agentmemory` 0.9.27, `aperture-cli` 0.0.13, `caveman-proxy` 2.1.0, `caveman-mcp` 2.1.0, `code-review-graph` 2.3.9, and skill bundles `mattpocock-skills` 1.3.1, `caveman-skills` 3.2.0, `ponytail-skills` 5.1.0, `code-review-graph-skills` 2.3.9.
- Because it holds several skill bundles, the output is itself a plugin directory with a synthesized `{ name, skills }` manifest and a flattened `passthru.skills`.

## Invariants

- Every component key is a toolbox package name and every pin is a version key in that package's `data.json`; `nix flake check` fails otherwise. `code-review-graph-skills` has no `data.json` of its own, so its pin is a version key of `packages/code-review-graph/data.json`.
- Versions are integer strings; a new composition is a new version key, existing ones are never edited.
- Available systems are the intersection of the components' `meta.platforms`.
- A skill name shipped by two component bundles fails the build.

## Side Effects

- None of its own: builds only symlink farms over component derivations, whose fetches are fixed-output.

## Verification

Run from the repository root:

```bash
nix build --no-link .#llm-toolchain.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
