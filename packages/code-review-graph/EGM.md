# code-review-graph

## Overview
Packages code-review-graph, a tree-sitter code knowledge graph served to agents over MCP (`code-review-graph serve`, stdio) and driven from its CLI, built from upstream's `uv.lock` with `toolboxLib.buildUvApplication` (uv2nix). nixpkgs' python set is not used because its `tree-sitter-language-pack` is outside upstream's `<1` pin.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildUvApplication { pname = "code-review-graph"; owner = "tirth8205"; repo = "code-review-graph"; python = pkgs.python313; ... }`.
- Versions: `2.3.9` (`_meta.default`).
- Installs the project's own entry points only (`$out/bin/code-review-graph`, `meta.mainProgram`); no optional extras.
- `data.json` also feeds [code-review-graph-skills](../code-review-graph-skills/EGM.md).

## Invariants
- The uv builder reads only `sha256` (`--unpack` hash of tag `v<version>`); every wheel and sdist is hash-pinned in upstream's lock.
- `owner`, `repo` and `rev` (the commit the tag points at) are there for the skill bundle; `rev` and `sha256` must name the same tree.
- Python stays 3.13: the lock has no 3.14 wheels for watchdog.
- Source fetched with `builtins.fetchTarball` (uv2nix reads the lock at eval time, avoiding import-from-derivation).

## Side Effects
- Eval/build time: fetch of the pinned source tarball and the wheels and sdists the lock names.
- Runtime (the packaged tool, not the build): writes the graph to `.code-review-graph/` at the repository root. Register it with agents through home-manager, never upstream's `code-review-graph install` (it rewrites agent configs).

## Verification
- Run: `nix build --no-link .#code-review-graph.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
