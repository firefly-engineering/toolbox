"""Entry point: python -m toolbox_docs"""

import argparse
from pathlib import Path

from .renderer import render_html
from .scanner import build_models, load_manifest

ASSETS_DIR = Path(__file__).parent / "assets"


def load_assets() -> tuple[str, str]:
    """Read the HTML template and CSS from disk. All render-time file I/O lives here."""
    template = (ASSETS_DIR / "index.html.tmpl").read_text()
    css = (ASSETS_DIR / "style.css").read_text()
    return template, css


DEFAULT_MANIFEST = Path("docs") / "_manifest.json"


def main():
    parser = argparse.ArgumentParser(prog="toolbox_docs")
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help=(
            "registry manifest, as produced by `nix eval --json .#manifest` "
            f"(default: {DEFAULT_MANIFEST})"
        ),
    )
    args = parser.parse_args()

    out_dir = Path.cwd() / "docs" / "_site"
    out_dir.mkdir(parents=True, exist_ok=True)

    packages, toolchains = build_models(load_manifest(args.manifest))
    template, css = load_assets()
    html = render_html(packages, toolchains, template=template, css=css)
    (out_dir / "index.html").write_text(html)
    print(
        f"Generated docs with {len(packages)} packages and {len(toolchains)} toolchains"
    )


if __name__ == "__main__":
    main()
