# toolbox_docs

## Overview

Static-site generator for the toolbox registry. It reads the registry manifest
produced by `nix eval --json .#manifest` (see
[`lib/manifest.nix`](/lib/manifest.nix)) and renders a single
`docs/_site/index.html` listing packages, toolchains and skill bundles. It does
not read `packages/*/data.json`: classification (`kind`), `releases` and
`inactive` come from the registry's `toolbox` stamp
([ADR 0004](/docs/adr/0004-registry-publishes-its-own-classification.md)).
Toolchains drop `releases` and `inactive`: `ToolchainInfo` has no such fields,
and toolchain rows render neither.

The pipeline is `load_manifest` -> `build_models` -> `render_html`. All file
I/O sits at the `__main__` edge; `scanner.build_models` and
`renderer.render_html` are pure.

## Interface

- `__main__.py`
  - `main()`: CLI entry point (`python -m toolbox_docs`, console script
    `toolbox-docs`). Flag `--manifest PATH` (default `docs/_manifest.json`).
    Writes `docs/_site/index.html` relative to the current working directory.
  - `load_assets() -> tuple[str, str]`: reads `assets/index.html.tmpl` and
    `assets/style.css`.
  - `ASSETS_DIR`, `DEFAULT_MANIFEST`: module constants.
- `scanner.py`
  - `load_manifest(path: Path) -> dict`: parses the manifest JSON; raises
    `ValueError` when the top-level `packages` key is missing.
  - `sorted_version_names(entry: dict) -> list[str]`: an entry's version names,
    newest first.
  - `build_models(manifest: dict) -> tuple[list[PackageInfo], list[ToolchainInfo], list[PackageInfo]]`:
    returns `(packages, toolchains, skill_bundles)`, routed by each entry's
    `kind`.
- `renderer.py`
  - `render_html(packages, toolchains, skill_bundles, *, template: str, css: str) -> str`:
    fills the `string.Template` placeholders `css`, `num_packages`,
    `total_versions`, `num_toolchains`, `num_skill_bundles`, `package_rows`,
    `toolchain_rows`, `skill_bundle_rows`.
- `models.py`: dataclasses `PackageInfo(name, default, versions, releases="", inactive=False)`,
  `ToolchainComponent(name, version)`,
  `ToolchainInfo(name, default, versions, expansion: dict[str, list[ToolchainComponent]] = {})`
  (`field(default_factory=dict)`).
- `sorting.py`: `version_key(v: str) -> list[int | str]`, the natural-sort key.
- `assets/`: `index.html.tmpl` (page template) and `style.css`. No code.
  Shipped as package data (`pyproject.toml` `tool.setuptools.package-data`).

## Invariants

- `scanner.build_models` and `renderer` do no filesystem access.
  `scanner.load_manifest` reads the manifest file, and `load_assets` reads the
  assets. `main` calls both.
- Classification is read, never inferred. `kind == "toolchain"` goes to
  `ToolchainInfo`, `kind == "skill-bundle"` goes to the third list, and any
  other kind becomes a package. Do not reintroduce name-suffix or file-presence
  heuristics (ADRs 0001 to 0003 record why they failed).
- Skill bundles share `PackageInfo` and the package row renderer. Only the
  section they render under differs
  ([ADR 0005](/docs/adr/0005-skill-bundles-get-their-own-section.md)).
- Version order is presentation: the manifest leaves it unspecified, and
  `sorted_version_names` sorts it newest-first with `version_key`. Entries are
  sorted by package name.
- Toolchain component expansions are sorted by component name. A version with
  no `components` entry expands to an empty list.
- `total_versions` counts package and skill-bundle versions, not toolchain
  versions.
- Every manifest-derived string reaches the HTML through `html.escape`.
- The template uses `Template.substitute`, so a placeholder missing from the
  template's inputs raises `KeyError`. Template and renderer change together.

## Side Effects

- `main` creates `docs/_site/` under the current working directory if absent
  and overwrites `docs/_site/index.html`. Run it from the repository root.
- `main` prints a one-line count summary to stdout.
- `load_manifest` and `load_assets` read files from disk. No network access.

## Verification

- Run: `cd docs && pytest` (CI runs `pytest docs/tests/ -v` from the repo root,
  after `pip install docs/[dev]`).
