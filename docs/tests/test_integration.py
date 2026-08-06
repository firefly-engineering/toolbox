"""Integration tests."""

from pathlib import Path

from toolbox_docs.__main__ import load_assets
from toolbox_docs.renderer import render_html
from toolbox_docs.scanner import scan_packages


def test_end_to_end_with_fixtures(tmp_packages: Path):
    """Generate HTML from test fixtures and verify basic structure."""
    packages, toolchains = scan_packages(tmp_packages)
    template, css = load_assets()
    html = render_html(packages, toolchains, template=template, css=css)
    assert "<!DOCTYPE html>" in html
    assert "mypkg" in html
    assert "my-toolchain" in html
    assert '<div class="stat-value">1</div>' in html


def test_every_registry_package_is_documented(repo_root: Path):
    """The docs must cover exactly what the flake exposes.

    The flake discovers packages by `builtins.readDir ./packages` + importing
    `default.nix`; the scanner discovers them by walking `packages/*/data.json`.
    Those two sets drifted apart silently once already (docs/adr/0002, 0003), so
    assert they agree rather than trusting each package to remember.
    """
    packages_dir = repo_root / "packages"
    if not packages_dir.exists():
        return

    from_flake = {d.name for d in packages_dir.iterdir() if (d / "default.nix").exists()}
    packages, toolchains = scan_packages(packages_dir)
    from_docs = {e.name for e in [*packages, *toolchains]}

    assert from_flake - from_docs == set(), "registry packages missing from the docs"
    assert from_docs - from_flake == set(), "documented entries the flake does not build"


def test_end_to_end_real_packages(repo_root: Path):
    """Generate HTML from real packages/ directory and verify structure."""
    packages_dir = repo_root / "packages"
    if not packages_dir.exists():
        return

    packages, toolchains = scan_packages(packages_dir)
    template, css = load_assets()
    html = render_html(packages, toolchains, template=template, css=css)

    assert "<!DOCTYPE html>" in html
    assert len(packages) > 0
    assert len(toolchains) > 0
    # Verify stats section has correct counts
    assert f'<div class="stat-value">{len(packages)}</div>' in html
    total_versions = sum(len(p.versions) for p in packages)
    assert f'<div class="stat-value">{total_versions}</div>' in html
    assert f'<div class="stat-value">{len(toolchains)}</div>' in html
