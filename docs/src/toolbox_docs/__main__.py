"""Entry point: python -m toolbox_docs"""

from pathlib import Path

from .renderer import render_html
from .scanner import scan_packages

ASSETS_DIR = Path(__file__).parent / "assets"


def load_assets() -> tuple[str, str]:
    """Read the HTML template and CSS from disk. All render-time file I/O lives here."""
    template = (ASSETS_DIR / "index.html.tmpl").read_text()
    css = (ASSETS_DIR / "style.css").read_text()
    return template, css


def main():
    repo_root = Path.cwd()
    packages_dir = repo_root / "packages"
    out_dir = repo_root / "docs" / "_site"
    out_dir.mkdir(parents=True, exist_ok=True)

    packages, toolchains = scan_packages(packages_dir)
    template, css = load_assets()
    html = render_html(packages, toolchains, template=template, css=css)
    (out_dir / "index.html").write_text(html)
    print(
        f"Generated docs with {len(packages)} packages and {len(toolchains)} toolchains"
    )


if __name__ == "__main__":
    main()
