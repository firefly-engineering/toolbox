"""Entry point: python -m toolbox_docs"""

from pathlib import Path

from .renderer import render_html
from .scanner import scan_packages


def main():
    repo_root = Path(__file__).resolve().parent.parent.parent.parent
    packages_dir = repo_root / "packages"
    out_dir = repo_root / "docs" / "_site"
    out_dir.mkdir(parents=True, exist_ok=True)

    packages, toolchains = scan_packages(packages_dir)
    html = render_html(packages, toolchains)
    (out_dir / "index.html").write_text(html)
    print(
        f"Generated docs with {len(packages)} packages and {len(toolchains)} toolchains"
    )


if __name__ == "__main__":
    main()
