# packages

## Overview

One directory per registry entry. The root `flake.nix` auto-discovers every subdirectory with `builtins.readDir ./packages` and imports `packages/<name>/default.nix` with `{ pkgs, lib, toolbox, toolboxLib }`. Each import returns a stamped `{ versions; default; toolbox; }` entry: 70 packages, 14 toolchains and 6 skill bundles. Version metadata lives in each `data.json`; the Nix code reads it. See [lib](../lib/EGM.md) for the builders and [AGENTS.md](../AGENTS.md) for the data schema.

Directories that hold no code and get no contract: `beadwork/patches/`, `jj-hunk/patches/` and `qmk/patches/` (vendored fork patches, resolved by `toolboxLib.resolvePatches`).

## Subdirectories & Boundaries

### Packages
- [agentmemory](./agentmemory/EGM.md): Packages agentmemory (persistent memory CLI and MCP server for AI coding agents, TypeScript bundled with tsdown) from the tagged GitHub source `rohitg00/agentmemory` with a custom `pkgs.buildNpmPackage` builder. Upstream commits no lockfile, so this package uses the documented last resort: a vendored, version-namespaced lockfile.
- [aperture-cli](./aperture-cli/EGM.md): Packages Tailscale's `aperture` launcher for agentic coding tools through Aperture, as a prebuilt per-platform binary from `tailscale/aperture-cli` GitHub releases.
- [beads](./beads/EGM.md) *(inactive)*: Packages beads (`bd`), an issue tracker for AI-supervised coding workflows, built from the tagged source `steveyegge/beads` with `toolboxLib.buildGoPackage`. Marked inactive (`_meta.inactive = true`): no new versions are added.
- [beads-rust](./beads-rust/EGM.md) *(inactive)*: Packages beads_rust (`br`), a local-first issue tracker storing tasks in SQLite, built from the tagged source `Dicklesworthstone/beads_rust` with `toolboxLib.buildRustPackage`. Marked inactive (`_meta.inactive = true`).
- [beads-viewer](./beads-viewer/EGM.md) *(inactive)*: Packages beads_viewer (`bv`), a terminal UI for the Beads issue tracker, built from the tagged source `Dicklesworthstone/beads_viewer` with `toolboxLib.buildGoPackage`. Marked inactive (`_meta.inactive = true`).
- [beadwork](./beadwork/EGM.md): Packages beadwork (`bw`), the git-native work tracker this repository itself uses, built from the tagged source `jallum/beadwork` with `toolboxLib.buildGoPackage`. Versions from 0.12.3 apply a vendored patch from the `sigma/beadwork` `tui` branch that adds a `bw-tui` binary.
- [biome](./biome/EGM.md): Packages Biome (formatter and linter for web languages) as a prebuilt single binary from `biomejs/biome` GitHub releases.
- [buck2](./buck2/EGM.md): Packages Meta's Buck2 build system as a prebuilt, zstd-compressed binary from `facebook/buck2` GitHub releases, and publishes the source commit each release tag points at.
- [buck2-prelude](./buck2-prelude/EGM.md): Pins the Buck2 prelude (`facebook/buck2-prelude`) at specific commits. The derivation is the fetched source tree itself; there is no build step.
- [bun](./bun/EGM.md): Packages the Bun JavaScript runtime, bundler, test runner and package manager as a prebuilt binary from `oven-sh/bun` GitHub releases.
- [bun-baseline](./bun-baseline/EGM.md): Packages Bun's baseline builds (no AVX2 requirement) for x86 hosts, from the same `oven-sh/bun` releases as [bun](./bun/EGM.md).
- [cargo-edit](./cargo-edit/EGM.md): Packages cargo-edit (Cargo subcommands such as `cargo add`, `cargo rm` and `cargo upgrade`), built from the tagged source `killercup/cargo-edit` with `toolboxLib.buildRustPackage`.
- [caveman-mcp](./caveman-mcp/EGM.md): Packages Caveman's MCP server (stdio): `caveman_retrieve` plus compress, stats and TOON tools over the shared recovery store. It is the agent-side recovery path that [caveman-proxy](./caveman-proxy/EGM.md) needs before it compresses traffic. Prebuilt binary from `JuliusBrussee/caveman` `bin-v<version>` releases.
- [caveman-proxy](./caveman-proxy/EGM.md): Packages Caveman's standalone gateway: a base-URL-swap reverse proxy for LLM traffic (record mode by default, `mode: compress` in `caveman.yaml` compresses in-process). Prebuilt binary from `JuliusBrussee/caveman` `bin-v<version>` releases. The Node `caveman` CLI that wraps it is not packaged.
- [code-review-graph](./code-review-graph/EGM.md): Packages code-review-graph, a tree-sitter code knowledge graph served to agents over MCP (`code-review-graph serve`, stdio) and driven from its CLI, built from upstream's `uv.lock` with `toolboxLib.buildUvApplication` (uv2nix). nixpkgs' python set is not used because its `tree-sitter-language-pack` is outside upstream's `<1` pin.
- [delta](./delta/EGM.md): Packages [delta](https://github.com/dandavison/delta), a syntax-highlighting pager for git, diff and grep output. A hybrid package: prebuilt release tarballs where upstream ships them for the host system, a Rust source build otherwise. Custom builder (not `buildPrebuiltBinary`, because it dispatches per system between two build strategies).
- [difftastic](./difftastic/EGM.md): Packages [difftastic](https://difftastic.wilfred.me.uk), a structural diff tool, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary` (`lib/prebuilt-binary.nix`).
- [elephant-goldfish-model](./elephant-goldfish-model/EGM.md): Ships the [Elephant-Goldfish Model](https://github.com/google/elephant-goldfish-model) agent plugin as upstream's whole pinned source tree. Deliberately not a `buildSkillBundle`: EGM skills read `agents/`, `resources/` and `docs/` at run time and its Claude manifest wires subagents and a PreToolUse hook, so the checkout itself is the plugin directory (it carries `.claude-plugin/`, `.codex-plugin/` and a root `plugin.json`).
- [entire](./entire/EGM.md): Packages the [Entire CLI](https://entire.io), which captures AI agent sessions as a searchable record alongside Git commits, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.
- [foundry](./foundry/EGM.md): Packages [Foundry](https://getfoundry.sh/), the Ethereum development toolkit, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.
- [gh](./gh/EGM.md): Packages [GitHub CLI](https://cli.github.com) (`gh`) from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.
- [gh-aw](./gh-aw/EGM.md): Packages the [`gh-aw`](https://github.com/github/gh-aw) GitHub CLI extension as a single prebuilt binary via `toolboxLib.buildPrebuiltBinary`. Note: `meta.description` reads "GitHub CLI extension for activity watching"; upstream describes gh-aw as GitHub Agentic Workflows.
- [gh-stack](./gh-stack/EGM.md): Packages the [`gh-stack`](https://github.com/github/gh-stack) GitHub CLI extension for stacked pull requests as a single prebuilt binary via `toolboxLib.buildPrebuiltBinary`.
- [git](./git/EGM.md): Builds [Git](https://git-scm.com) from the kernel.org release tarball with a custom `stdenv.mkDerivation` builder.
- [git-lfs](./git-lfs/EGM.md): Packages [Git LFS](https://git-lfs.com) from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.
- [go](./go/EGM.md): Builds the [Go](https://go.dev) toolchain from the official source tarball, bootstrapped with nixpkgs' `pkgs.go`. It is the Go that every toolbox Go package compiles with (through `toolboxLib.buildGoPackage` or `buildGoModule.override { go = ...; }`).
- [go-licenses](./go-licenses/EGM.md): Builds [go-licenses](https://github.com/google/go-licenses), which reports the licenses of a Go package and its dependencies, from its tagged source via `toolboxLib.buildGoPackage` (`lib/go-package.nix`).
- [golangci-lint](./golangci-lint/EGM.md): Packages [golangci-lint](https://golangci-lint.run/), the Go linters runner, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.
- [gopls](./gopls/EGM.md): Builds [gopls](https://pkg.go.dev/golang.org/x/tools/gopls), the official Go language server, from the `golang/tools` monorepo via `toolboxLib.buildGoPackage`.
- [gotestsum](./gotestsum/EGM.md): Builds [gotestsum](https://github.com/gotestyourself/gotestsum), a human-friendly runner for `go test`, from its tagged source via `toolboxLib.buildGoPackage`.
- [hunk](./hunk/EGM.md): Packages [hunk](https://github.com/modem-dev/hunk), a review-first terminal diff viewer for agentic coders, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`. The archive also ships agent skills, which are kept in the output.
- [jj](./jj/EGM.md): Jujutsu (`jj`) DVCS built from the `jj-vcs/jj` tag with toolbox's pinned Rust via `toolboxLib.buildRustPackage`; pname `jujutsu`.
- [jj-hunk](./jj-hunk/EGM.md): `jj-hunk` built from the `laulauland/jj-hunk` GitHub tag with toolbox's pinned Rust via `toolboxLib.buildRustPackage`.
- [jjui](./jjui/EGM.md): `jjui`, a TUI for Jujutsu, installed from prebuilt upstream release zips via `toolboxLib.buildPrebuiltBinary`.
- [jq](./jq/EGM.md): `jq` JSON processor installed from upstream's static per-platform release binary via `toolboxLib.buildPrebuiltBinary`.
- [jrsonnet](./jrsonnet/EGM.md): `jrsonnet` (Rust Jsonnet implementation) built from the `CertainLach/jrsonnet` tag via `toolboxLib.buildRustPackage`.
- [just](./just/EGM.md): `just` command runner installed from upstream release tarballs via `toolboxLib.buildPrebuiltBinary`, with man page and completions.
- [mdbook](./mdbook/EGM.md): `mdbook` installed from upstream's prebuilt release tarballs via `toolboxLib.buildPrebuiltBinary`.
- [mdbook-admonish](./mdbook-admonish/EGM.md): `mdbook-admonish` mdBook preprocessor built from the `tommilligan/mdbook-admonish` tag via `toolboxLib.buildRustPackage`.
- [mdbook-footnote](./mdbook-footnote/EGM.md): `mdbook-footnote` mdBook preprocessor built from the `daviddrysdale/mdbook-footnote` tag via `toolboxLib.buildRustPackage`.
- [mdbook-graphviz](./mdbook-graphviz/EGM.md): `mdbook-graphviz` mdBook preprocessor built from source via `toolboxLib.buildRustPackage` and wrapped to find Graphviz.
- [mdbook-mermaid](./mdbook-mermaid/EGM.md): `mdbook-mermaid` mdBook preprocessor built from the `badboy/mdbook-mermaid` tag via `toolboxLib.buildRustPackage`.
- [nil](./nil/EGM.md): `nil` Nix language server built from the `oxalica/nil` date tag via `toolboxLib.buildRustPackage`, with version-namespaced vendored `Cargo.lock` files.
- [nix](./nix/EGM.md): The Nix package manager built from the `NixOS/nix` tag with meson on the LLVM stdenv; a custom `mkDerivation` with one builder variant per meson flag set.
- [nixfmt-tree](./nixfmt-tree/EGM.md): Zero-setup Nix formatter: toolbox's pinned `treefmt` wrapped with nixpkgs `nixfmt` and a generated `treefmt.toml`; a custom `symlinkJoin` builder.
- [nodejs](./nodejs/EGM.md): Node.js installed from the official nodejs.org per-platform binary tarball; a custom `mkDerivation` (whole toolchain tree, so not `buildPrebuiltBinary`).
- [openspec](./openspec/EGM.md): OpenSpec CLI (pnpm/TypeScript) built from the `Fission-AI/OpenSpec` tag with `buildNpmPackage`, dependencies pinned by upstream's `pnpm-lock.yaml` through `fetchPnpmDeps`.
- [platform-tools](./platform-tools/EGM.md): Solana `platform-tools` (sbpf rustc + LLVM for `cargo-build-sbf`) installed from prebuilt per-platform tarballs; a custom `mkDerivation` using `toolboxLib.unpackFlat`.
- [pnpm](./pnpm/EGM.md): pnpm installed from its standalone per-platform release tarball; a custom `mkDerivation` using `toolboxLib.unpackFlat`, made a drop-in for nixpkgs' pnpm build helpers.
- [protobuf](./protobuf/EGM.md): `protoc` and the well-known type definitions installed from upstream's prebuilt release zips via `toolboxLib.buildPrebuiltBinary`.
- [protoc-gen-go](./protoc-gen-go/EGM.md): `protoc-gen-go` built from the `protocolbuffers/protobuf-go` tag with toolbox's pinned Go via `toolboxLib.buildGoPackage`.
- [pulumi](./pulumi/EGM.md): Pulumi CLI and its language hosts installed from upstream's prebuilt release tarballs via `toolboxLib.buildPrebuiltBinary`.
- [pytest](./pytest/EGM.md): pytest at a pinned PyPI version, built by overriding nixpkgs' `python3Packages.pytest` source; a custom `runCommand` exposing its entry points.
- [python](./python/EGM.md): CPython from astral-sh `python-build-standalone` (`install_only_stripped`) tarballs; a custom `mkDerivation` installing the whole interpreter tree.
- [qmd](./qmd/EGM.md): Packages [qmd](https://github.com/tobi/qmd) (Query Markup Documents: on-device hybrid BM25/vector/LLM-rerank search over markdown), a Bun/TypeScript application, built from the tagged GitHub source. Adapted from upstream's own `flake.nix`: a fixed-output `node_modules` derivation (`bun install --frozen-lockfile`) feeds a main build that compiles the `better-sqlite3` native addon with `node-gyp` and wraps `bun src/cli/qmd.ts`.
- [qmk](./qmk/EGM.md): Packages the [QMK CLI](https://github.com/qmk/qmk_cli) by overriding nixpkgs' `pkgs.qmk` Python package with a toolbox-pinned PyPI release plus vendored fork patches.
- [qmk_hid](./qmk_hid/EGM.md): Packages [qmk_hid](https://github.com/FrameworkComputer/qmk_hid), a CLI to talk to QMK devices over their raw HID interface, built from source with the toolbox Rust toolchain.
- [reindeer](./reindeer/EGM.md): Packages [reindeer](https://github.com/facebookincubator/reindeer), which generates Buck build rules from Cargo, built from source with the toolbox Rust toolchain.
- [ruff](./ruff/EGM.md): Packages [ruff](https://github.com/astral-sh/ruff), Astral's Python linter and formatter, from upstream's prebuilt release tarballs.
- [rust](./rust/EGM.md): Packages the official Rust toolchain from `static.rust-lang.org` prebuilt dist tarballs, installed with upstream's `install.sh`. This is the Rust every source-built Rust package in the registry compiles with.
- [rust-analyzer](./rust-analyzer/EGM.md): Packages [rust-analyzer](https://rust-analyzer.github.io/), the Rust language server, from upstream's prebuilt gzip-compressed binaries.
- [solc](./solc/EGM.md): Packages [solc](https://soliditylang.org/), the Solidity compiler, from upstream's static release binaries.
- [sops](./sops/EGM.md): Packages [sops](https://getsops.io), the secrets-file editor, from upstream's prebuilt release binaries.
- [treefmt](./treefmt/EGM.md): Packages [treefmt](https://github.com/numtide/treefmt), the multi-formatter runner, from upstream's prebuilt release tarballs.
- [tuicr](./tuicr/EGM.md): Packages [tuicr](https://github.com/agavra/tuicr), a code review TUI with vim keybindings. Recent versions are built from the tagged source tree so the pin is the same source [tuicr-skills](./tuicr-skills/EGM.md) bundles its skill from; the oldest version uses the prebuilt release.
- [ty](./ty/EGM.md): Packages [ty](https://github.com/astral-sh/ty), Astral's Python type checker, from upstream's prebuilt release tarballs.
- [typescript](./typescript/EGM.md): Packages the TypeScript compiler from the npm registry. Three builder variants cover the JavaScript compiler (6.x), the TypeScript 7 native-preview channel (`tsgo`), and released TypeScript 7 (native Go `tsc`).
- [uv](./uv/EGM.md): Packages [uv](https://github.com/astral-sh/uv), Astral's Python package and project manager, from upstream's prebuilt release tarballs.
- [vitaly](./vitaly/EGM.md): Packages [vitaly](https://github.com/bskaplou/vitaly), a Vial-compatible CLI for QMK keyboards, built from source with the toolbox Rust toolchain.
- [yq](./yq/EGM.md): Packages [yq](https://mikefarah.gitbook.io/yq/) (mikefarah), the YAML/JSON/XML/CSV/TOML processor, from upstream's prebuilt release binaries.

### Toolchains
- [buck2-toolchain](./buck2-toolchain/EGM.md): Toolchain meta-package bundling buck2 with reindeer (Buck2 BUILD-file generator for Cargo) via `toolboxLib.buildToolchain` (`symlinkJoin`).
- [go-toolchain](./go-toolchain/EGM.md): A toolchain meta-package that bundles a pinned set of Go tools into one `symlinkJoin` via `toolboxLib.buildToolchain`. It contains no build logic of its own.
- [js-toolchain](./js-toolchain/EGM.md): JavaScript toolchain (`nodejs`, `biome`, `bun`, `pnpm`) assembled with `toolboxLib.buildToolchain`.
- [kbd-toolchain](./kbd-toolchain/EGM.md): Keyboard-firmware toolchain (`qmk`, `qmk_hid`, `vitaly`) assembled with `toolboxLib.buildToolchain`.
- [llm-toolchain](./llm-toolchain/EGM.md): LLM/agent toolchain (CLIs, MCP servers and Claude Code skill bundles) assembled with `toolboxLib.buildToolchain`.
- [mdbook-toolchain](./mdbook-toolchain/EGM.md): mdBook plus its preprocessors (admonish, mermaid, footnote, graphviz) assembled with `toolboxLib.buildToolchain`.
- [nix-toolchain](./nix-toolchain/EGM.md): Nix editing toolchain (`nil` language server, `nixfmt-tree` formatter) assembled with `toolboxLib.buildToolchain`.
- [proto-toolchain](./proto-toolchain/EGM.md): Protocol Buffers toolchain (`protoc` + well-known types, `protoc-gen-go`) assembled with `toolboxLib.buildToolchain`.
- [python-toolchain](./python-toolchain/EGM.md): Python toolchain (`python`, `uv`, `ruff`, `pytest`, `ty`) assembled with `toolboxLib.buildToolchain`.
- [rust-toolchain](./rust-toolchain/EGM.md): Bundles the Rust toolchain, its language server and `cargo-edit`. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.
- [solana-toolchain](./solana-toolchain/EGM.md): Solana on-chain toolchain: nixpkgs `solana-cli`, `anchor` and `rustup`, plus a host-independent `cargo-build-sbf` that builds against a pinned, offline SBF SDK (nixpkgs' SDK scaffolding with toolbox `platform-tools` mounted in). Consumers put it on a dev shell with no `SBF_SDK_PATH`/`RUSTUP_HOME`/`--tools-version` setup and no platform-tools download; `anchor build` works because it finds the wrapped `cargo-build-sbf` on `PATH`.
- [solidity-toolchain](./solidity-toolchain/EGM.md): Bundles the Solidity compiler and Foundry. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.
- [typescript-toolchain](./typescript-toolchain/EGM.md): Bundles the TypeScript compiler with Node.js, Biome, Bun and (from version 4) pnpm. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.
- [vcs-toolchain](./vcs-toolchain/EGM.md): Bundles version-control tooling: Jujutsu and its UIs, git and GitHub CLIs, diff viewers and review tools. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.

### Skill bundles
- [caveman-skills](./caveman-skills/EGM.md): Skill bundle packaging Caveman's self-contained agent skills as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`: the voice modes, terse commit and review skills, and the help card.
- [code-review-graph-skills](./code-review-graph-skills/EGM.md): Skill bundle packaging code-review-graph's agent skills (`skills/*/SKILL.md`: review-pr, review-changes, explore-codebase, and others) as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`. It has no `data.json` of its own.
- [herdr-skills](./herdr-skills/EGM.md): Packages Herdr's agent skill (`skills/herdr/` in [herdrdev/herdr](https://github.com/herdrdev/herdr)) as a Claude Code plugin directory via `toolboxLib.buildSkillBundle` (`lib/skill-bundle.nix`). The skill teaches an agent to drive Herdr (workspaces, tabs, panes, neighbouring agents) from inside a Herdr-managed pane.
- [mattpocock-skills](./mattpocock-skills/EGM.md): Matt Pocock's agent skills packaged as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`, restricted to upstream's manifest.
- [ponytail-skills](./ponytail-skills/EGM.md): Ponytail agent skills (`ponytail` mode plus audit/review/debt/gain/help) packaged as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`, without upstream's hooks.
- [tuicr-skills](./tuicr-skills/EGM.md): Packages tuicr's agent skill (`skills/tuicr/`: `SKILL.md` plus the tmux/Zellij/Herdr wrapper scripts) as a Claude Code plugin directory. It has no `data.json` of its own: its source pin is read from [tuicr](./tuicr/EGM.md)'s `data.json`, so the skill always matches the tuicr binary of the same version.
