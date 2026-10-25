# src

## Overview

setuptools source root for the `toolbox-docs` distribution
(`[tool.setuptools.packages.find] where = ["src"]` in
[`docs/pyproject.toml`](/docs/pyproject.toml)). It holds one importable
package. `toolbox_docs.egg-info/` is build metadata, not source.

## Subdirectories & Boundaries

- toolbox_docs: [./toolbox_docs/EGM.md](./toolbox_docs/EGM.md) - Pure
  manifest-to-HTML generator. `load_manifest` -> `build_models` ->
  `render_html`, with file I/O only at the `__main__` edge. Writes
  `docs/_site/index.html`.
