"""Integration tests."""

from pathlib import Path

from toolbox_docs.renderer import render_html
from toolbox_docs.scanner import scan_packages


def test_end_to_end_with_fixtures(tmp_packages: Path):
    """Generate HTML from test fixtures and verify basic structure."""
    packages, toolchains = scan_packages(tmp_packages)
    html = render_html(packages, toolchains)
    assert "<!DOCTYPE html>" in html
    assert "mypkg" in html
    assert "my-toolchain" in html
    assert '<div class="stat-value">1</div>' in html


def test_end_to_end_real_packages(repo_root: Path):
    """Generate HTML from real packages/ directory and verify structure."""
    packages_dir = repo_root / "packages"
    if not packages_dir.exists():
        return

    packages, toolchains = scan_packages(packages_dir)
    html = render_html(packages, toolchains)

    assert "<!DOCTYPE html>" in html
    assert len(packages) > 0
    assert len(toolchains) > 0
    # Verify stats section has correct counts
    assert f'<div class="stat-value">{len(packages)}</div>' in html
    total_versions = sum(len(p.versions) for p in packages)
    assert f'<div class="stat-value">{total_versions}</div>' in html
    assert f'<div class="stat-value">{len(toolchains)}</div>' in html
