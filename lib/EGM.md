# toolboxLib (`lib/`)

## Overview

`lib/` is the toolbox registry's Nix library, imported by `flake.nix` as
`toolboxLib = import ./lib { inherit lib; pythonInputs = ...; }` and passed to
every `packages/<name>/default.nix` as the `toolboxLib` argument.

It has three jobs:

1. **Assembling entries.** It turns a `data.json` (version metadata) plus a
   `builders` attrset into a registry entry: `{ versions; default; toolbox; }`.
2. **Builder helpers.** These return `version: versionData: derivation`
   functions for the common package shapes: prebuilt binaries, Rust, Go,
   Python with `uv.lock`, skill bundles and toolchains.
3. **Registry-wide functions.** These cover the flake's output naming, the
   eval-time invariant check (`nix flake check`) and the JSON manifest that
   the docs generator uses.

`default.nix` holds the small registry helpers. It merges in the other files
with `//`, so every exported name below is reachable as `toolboxLib.<name>`.

Legacy prose documentation for these helpers lives in the repository's
root `AGENTS.md` (sections *Adding a New Package*, *Prebuilt-Binary Packages*,
*Source-Built Rust and Go Packages*, *Python Applications*, *Adding a
Skill Bundle*, *What the Registry Publishes*, *Verification Checklist*). The
code in this directory is authoritative where they differ.

## Interface

### Import signature

- `import ./lib { lib; pythonInputs ? null; }`. `lib` is nixpkgs' `lib`.
  `pythonInputs` is `{ pyproject-nix; uv2nix; pyproject-build-systems; }`.
  It is needed only by `buildUvApplication`. `flake.nix` imports lib without
  it for `registryOutputs`, `checkRegistry` and `registryManifest`.

### Registry entry shape (the contract every package returns)

```nix
{
  versions = { "<version>" = <derivation>; ... };
  default  = "<version>";            # _meta.default
  toolbox  = {                       # stamp, see mkStamp
    kind       = "package" | "toolchain" | "skill-bundle";
    releases   = <_meta.releases or null>;
    inactive   = <_meta.inactive or false>;
    components = null | { "<version>" = { "<component>" = "<pin>"; }; };
  };
}
```

### `default.nix`: core registry helpers

| Symbol | Signature | Behaviour |
|---|---|---|
| `readData` | `path -> { meta; versions; }` | Parses a `data.json`. `meta` = `_meta`; `versions` = every other top-level key. |
| `buildVersions` | `name -> builders -> versionEntries -> { <version> = drv; }` | For each version, calls `builders.${versionData.builder or "default"} version versionData`. Throws `Unknown builder '<b>' for <name> <version>`. Exported, but no package calls it directly (packages go through `buildPackage`). |
| `buildPackage` | `{ name; dataPath; builders; } -> entry` | The standard entry point. Calls `readData` and `buildVersions`, then stamps `kind = "package"`. |
| `buildToolchain` | `{ toolbox; pkgs; name; dataPath; } -> entry` | Each version entry is a `{ <component> = <version>; }` map. It builds `pkgs.symlinkJoin` named `<name>-<version>` over `toolbox.<component>.versions.<ver>`. See *Invariants* for how platforms and bundled skill manifests are handled. Stamps `kind = "toolchain"`, with `components` set to the whole versions attrset. |
| `resolveTool` | `registry -> name -> version\|null -> drv` | Looks up a tool. A `null` version means `entry.default`. Throws `Unknown tool ...` / `Unknown version ...`. |
| `resolvePatches` | `packageDir -> versionData -> [ path ]` | Returns `map (p: packageDir + "/${p.file}") (versionData.patches or [])`. Safe to call when there are no patches. |
| `availableVersions` | `hostPlatform -> entry -> { <version> = drv; }` | Filters `entry.versions` with `lib.meta.availableOn hostPlatform`. `registryOutputs` and `checkRegistry` use it. `registryManifest` inlines the same `filterAttrs`/`availableOn` logic instead. |
| `versionToAttr` | `string -> string` | Replaces `.` with `_` (`"1.25.6"` -> `"1_25_6"`). |
| `registryOutputs` | `{ pkgs; registry; } -> { nested; flat; }` | The flake's naming contract, computed from `availableVersions`. `nested.<name>` = `{ <ver_attr> = drv; default = drv; }` (this is `legacyPackages`). `flat` = `"<name>-<ver_attr>"`, the bare `"<name>"` (the default version), and a deprecated `"<name>-default"` that emits a `builtins.trace` warning (this is `packages`). If the default version is unavailable, `default`, the bare name and `-default` are left out. A package with no available versions contributes nothing to `flat` and an empty set to `nested`. |
| `mkStamp` | `{ kind; meta; components ? null; } -> stamp` | Builds the `toolbox` stamp from `_meta`. Required on any `{ versions; default; }` built by hand (the only one is `packages/solana-toolchain`). |

### `prebuilt-binary.nix`

- `buildPrebuiltBinary { pkgs; pname; platforms; url; binaries; sourceRoot ? null; patchelf ? true; extraLibs ? []; symlinks ? {}; postInstall ? ""; meta ? {}; } -> version: versionData: drv`
  - `platforms` maps each system to an asset string. `url` is
    `{ version, platform } -> URL`. The source is
    `fetchurl { url; hash = versionData.<system>.sha256; }`.
  - `binaries` entries are either a string (installed under its basename) or
    `{ from; to; }`, where `from` may be a function
    `{ version, platform } -> string`.
  - `sourceRoot = null` sets `dontUnpack`. In that case a `.zst`, `.gz`,
    `.xz` or `.bz2` URL suffix picks a decompressor (`zstd`, `gzip`, `xz` or
    `bzip2`, added to `nativeBuildInputs`) that streams `$src` into
    `$out/bin/<to>`. Otherwise `$src` is installed as it is. Either way
    `from` is not used as a path: it only supplies the default `to`.
  - A string or function `sourceRoot` names the unpacked directory. The
    literal `"."` uses `unpackFlat`.
  - `.zip` URLs add `unzip`. `patchelf && isLinux` adds `autoPatchelfHook`,
    plus `cc.cc.lib` and `extraLibs` in `buildInputs`. `installShellFiles` is
    always present.
  - `symlinks` (`{ link = target; }`) creates `$out/bin/<link> -> $out/bin/<target>`.
  - `postInstall` runs inside `installPhase`.
- `unpackFlat`: the attrset `{ sourceRoot = "."; preUnpack = "mkdir source; cd source"; }`.
  It is shared with hand-written builders of flat archives (`packages/pnpm`,
  `packages/platform-tools`).

### `rust-package.nix`

- `buildRustPackage { pkgs; toolbox; pname; owner; repo; rev ? ({version}: "v${version}"); extraArgs ? {}; meta ? {}; } -> version: versionData: drv`
  - The Rust toolchain is `toolbox.rust.versions.${versionData.rust}`, wrapped
    with `pkgs.makeRustPlatform { rustc = cargo = rust; }`.
  - The source is `fetchFromGitHub` with `hash = versionData.sha256`.
  - `doCheck = false`.
  - `cargoHash` is set only when `versionData ? cargoHash`. Packages that
    vendor a lockfile pass `cargoLock` through `extraArgs`.
  - `extraArgs` is an attrset or a function `{ version, versionData, rust } -> attrset`.
    It is merged last.

### `go-package.nix`

- `buildGoPackage { pkgs; toolbox; pname; owner; repo; rev ? ...; subPackages ? [ "." ]; extraArgs ? {}; meta ? {}; } -> version: versionData: drv`
  - Calls `(pkgs.buildGoModule.override { go = toolbox.go.versions.${versionData.go}; })`.
  - The source is `fetchFromGitHub` with `versionData.sha256`.
  - `vendorHash = versionData.vendorHash`, which is always read.
  - `subPackages = versionData.subPackages or subPackages`.
  - `doCheck = false`.
  - `extraArgs` is an attrset or a function `{ version, versionData, go } -> attrset`.
    It is merged last.

### `uv-package.nix`

- `buildUvApplication { pkgs; pname; owner; repo; rev ? ...; python ? pkgs.python3; overrides ? (_: _: {}); meta ? {}; } -> version: versionData: drv`
  - The source is `builtins.fetchTarball` of the GitHub archive with
    `sha256 = versionData.sha256`. This is a hash-pinned fetch at eval time,
    not IFD.
  - uv2nix runs `loadWorkspace` on it. The overlays are
    `pyproject-build-systems.overlays.wheel`, then
    `mkPyprojectOverlay { sourcePreference = "wheel"; }`, then `overrides`.
  - The result is `mkVirtualEnv` over `workspace.deps.default`, wrapped with
    `pyproject-nix.build.util.mkApplication`, which exposes only the project's
    own entry points. `meta` is applied via `overrideAttrs`.
  - `pname` must match the uv project name, because it is used as
    `pythonSet.${pname}`.
  - Throws if lib was imported without `pythonInputs`.

### `skill-bundle.nix`

- `buildSkillBundle { pkgs; name; dataPath; } -> entry`. Stamps `kind = "skill-bundle"`.
  - Each version's `fetchFromGitHub { owner; repo; rev; hash = sha256; }`
    becomes a `runCommand "<name>-<version>"` plugin directory containing
    `.claude-plugin/plugin.json` and the selected skill directories, at their
    upstream-relative paths.
  - The candidates are either the upstream manifest's `.skills`
    (`fromClaudePlugin`, which defaults from `_meta.fromClaudePlugin`, else
    `false`), or every `skills/**/SKILL.md` directory.
  - `select` and `exclude` filter by basename, and `exclude` wins.
  - When `fromClaudePlugin` is set, the upstream manifest is shipped with
    `skills` rewritten to the selection. Otherwise the manifest is a
    synthesized `{ name; skills; }`.
  - `pluginJsonPath` defaults to `.claude-plugin/plugin.json`.
  - `passthru.skills = flattenSkills ...`.
- `flattenSkills { pkgs; name; version; bundle; } -> drv`
  (`runCommand "<name>-<version>-skills"`). It builds a one-folder-per-skill
  copy from `bundle/.claude-plugin/plugin.json`'s `.skills`. Two skills with
  the same basename fail the build. `buildToolchain` also uses it.

### `check-registry.nix`

- `checkRegistry { pkgs; systemRegistries; packagesDir; } -> drv`.
  `systemRegistries` is a list of `{ system; registry; hostPlatform; }`.
  - If anything is wrong, it throws one report that lists every problem. The
    shape and stamp checks run against the first system's registry only. The
    checks are:
    - patch files: every `packages/*/data.json` `patches[].file` exists on disk;
    - shape: each entry is `{ versions; default; }`, and `default` is in
      `versions` unless `versions` is empty;
    - stamp: a `toolbox` stamp exists, `kind` is in
      `[ "package" "toolchain" "skill-bundle" ]`, and a toolchain stamp has
      non-null `components`.
  - It then forces `drvPath` for every available version on **every** system.
    String context is discarded, so nothing is built.
  - The result is a host-native `runCommand "toolbox-registry-check"` that
    writes `$out/instantiated` (the drvPaths) and `$out/summary`.

### `manifest.nix`

- `registryManifest { systemRegistries; } -> { packages.<name> = { kind; default; releases; inactive; components; versions.<version>.systems = [ system ]; }; }`.
  This is exposed as the flake output `.#manifest`. The package and version
  keys come from the first registry. Systems are listed per version by
  `lib.meta.availableOn`. Version order is deliberately unspecified.

### Subdirectories

- None.

## Invariants

- **Every registry entry is stamped.** `buildPackage`, `buildToolchain` and
  `buildSkillBundle` stamp automatically. A hand-built entry must call
  `mkStamp`, or `checkRegistry` fails. Classification (`kind`) is stated by the
  builder, and nothing infers it from names or `data.json` keys (see
  `docs/adr/0001`, `docs/adr/0004`).
- **`_meta.default` must be a key of `versions`** wherever `versions` is
  non-empty, which `checkRegistry` enforces. `_meta` itself is required:
  `readData` reads `data._meta` without a fallback.
- **Builder dispatch:** `versionData.builder or "default"` must name a key of
  `builders`. Adding a builder variant must never change the derivations of
  existing versions.
- **Builder helpers do not read `data.json`.** `buildPrebuiltBinary`,
  `buildRustPackage`, `buildGoPackage` and `buildUvApplication` return
  `version: versionData: drv`, and that function slots into
  `buildPackage { builders = { default = ...; }; }`.
- **Hashes come from `versionData`.** Each helper reads a fixed field:
  - prebuilt: `versionData.<system>.sha256`;
  - Rust: `sha256`, plus `rust` and an optional `cargoHash`;
  - Go: `sha256`, `go` and `vendorHash`;
  - uv: `sha256` only;
  - skill bundles: `owner`, `repo`, `rev` and `sha256`.

  A missing field shows up when the version is instantiated, which is what
  `checkRegistry` forces.
- **Platform availability is declared through `meta.platforms`, and code that
  lists versions respects it.**
  - `buildPrebuiltBinary` defaults `meta.platforms` to
    `attrNames platforms`, and an explicit `meta.platforms` wins.
  - `buildToolchain` sets the intersection of its components'
    `meta.platforms`. A component without `meta.platforms` adds no
    constraint.
  - `registryOutputs` and `checkRegistry` filter through
    `availableVersions`, and `registryManifest` inlines the same
    `lib.meta.availableOn` filter, so they never force unavailable derivations, which
    nixpkgs would refuse to evaluate.
- **Choosing the attribute set must not call per-platform functions.**
  `buildPrebuiltBinary` decides between `dontUnpack`, `unpackFlat` and
  `sourceRoot` from the literal `sourceRoot` argument. Calling a function
  `sourceRoot` would throw on systems the package does not cover.
- **Toolchain manifests:** a toolchain with 0 or 1 skill-bundle components
  (recognised by `toolbox.kind == "skill-bundle"`) is a plain `symlinkJoin`.
  With two or more, `postBuild` uses `jq` to replace the joined
  `.claude-plugin/plugin.json` with `{ name; skills = concat; }`, and fails if
  two skills share a basename. Any toolchain with at least one bundle gets
  `passthru.skills`.
- **Reproducibility:** skill selection runs inside the build sandbox with `jq`,
  never at eval time. Apart from `buildUvApplication`'s hash-pinned
  `fetchTarball`, there is no import-from-derivation.
- **Refactors must not change derivations.** A behaviour-preserving change to
  any helper must leave every `drvPath` unchanged (see *Verification*).
- **Known comment drift:** the comment above `buildPackage` in `default.nix`
  still cites `packages/bun-baseline` as a direct `buildVersions` user. That
  package now uses `buildPackage` plus `buildPrebuiltBinary`, and no package
  calls `buildVersions` directly.

## Side Effects

- **Evaluation-time file reads:** `readData` reads `data.json` files with
  `builtins.readFile`. `checkRegistry` calls `builtins.readDir`,
  `builtins.pathExists` and `builtins.readFile` on `packagesDir`.
- **Evaluation-time network fetch:** `buildUvApplication` runs
  `builtins.fetchTarball` (hash-pinned) on GitHub so uv2nix can parse
  `uv.lock`.
- **Build-time network (fixed-output derivations only):** `fetchurl` in
  `buildPrebuiltBinary` and `fetchFromGitHub` in the Rust, Go and skill-bundle
  helpers. The Rust and Go dependency fetchers are FODs pinned by
  `cargoHash` / `vendorHash`.
- **Eval warnings:** forcing `flat."<name>-default"` emits a `builtins.trace`
  deprecation warning.
- **Throws:**
  - an unknown builder, tool or version;
  - an unsupported system (`buildPrebuiltBinary`): the same
    `<pname> <version> has no binary for <system>` message fires when the
    system is missing from `platforms` or from `versionData`;
  - a missing `pythonInputs`;
  - `checkRegistry`'s aggregated problem report.
- **Build failures:** colliding skill basenames (`flattenSkills`, toolchain
  manifest merge), and a candidate skill path missing from the source
  (`buildSkillBundle`, for paths the upstream manifest lists). A `select` name
  that matches no candidate is dropped silently, with no build failure.
- No helper mutates the repository or any state outside the Nix store.

## Verification

- Run the registry gate, the same one `.github/workflows/check.yml` runs. Do
  not add `--all-systems`.

  ```bash
  printf '%s' "$PWD" > .devenv-root
  nix flake check --impure \
    --override-input devenv-root "file+file://$PWD/.devenv-root"
  ```

- After refactoring a builder, compare every `drvPath` before and after the
  change. The two outputs must be identical.

  ```bash
  nix eval --json --impure --expr '
    let f = builtins.getFlake (toString ./.);
        pkgs = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
        tl = import ./lib { inherit (pkgs) lib; };
    in pkgs.lib.mapAttrs (_: e:
         pkgs.lib.mapAttrs (_: d: d.drvPath)
           (tl.availableVersions pkgs.stdenv.hostPlatform e))
       f.registry.${builtins.currentSystem}'
  ```

- Check the manifest output: `nix eval --json .#manifest`, which
  `.github/workflows/docs.yml` consumes.
