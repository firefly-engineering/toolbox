# docs

## Overview

Python project (`toolbox-docs`, `requires-python >= 3.12`, declared in
`pyproject.toml`) that generates the toolbox registry's GitHub Pages site. Its
only input is the registry manifest from `nix eval --json .#manifest`.
`.github/workflows/docs.yml` evaluates the manifest into
`docs/_manifest.json`, runs `python -m toolbox_docs --manifest docs/_manifest.json`,
and publishes `docs/_site/`.

The directory also holds non-code material outside this contract: `adr/`
(architecture decision records), `agents/` (agent workflow docs), `tests/`
(pytest suite on fixtures, no Nix needed), and the gitignored `_site/` output.

## Subdirectories & Boundaries

- src: [./src/EGM.md](./src/EGM.md) - setuptools source root holding the
  `toolbox_docs` package, a pure manifest-to-HTML generator that reads
  classification from the registry's `toolbox` stamp and never from
  `packages/*/data.json`.

## Verification

- Run: `cd docs && pytest` (CI: `pip install docs/[dev]`, then
  `pytest docs/tests/ -v`).
