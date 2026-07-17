"""Tests for renderer module."""

from toolbox_docs.models import PackageInfo, ToolchainComponent, ToolchainInfo
from toolbox_docs.renderer import _render_package_rows, _render_toolchain_rows, render_html

# A fixed inline template/css so render_html is exercised without touching the
# real asset files on disk. It carries every substitution placeholder the
# transform fills in.
INLINE_TEMPLATE = """<!DOCTYPE html>
<title>Toolbox Package Registry</title>
<style>$css</style>
<div class="stat-value">$num_packages</div>
<div class="stat-value">$total_versions</div>
<div class="stat-value">$num_toolchains</div>
<tbody>$package_rows</tbody>
<tbody>$toolchain_rows</tbody>
"""
INLINE_CSS = "body { color: black; }"


def test_default_version_highlighted():
    pkg = PackageInfo(name="foo", default="2.0", versions=["2.0", "1.0"])
    html = _render_package_rows([pkg])
    assert 'class="version default">2.0</span>' in html
    assert 'class="version">1.0</span>' in html


def test_inactive_badge_and_row_class():
    pkg = PackageInfo(
        name="old", default="1.0", versions=["1.0"], inactive=True
    )
    html = _render_package_rows([pkg])
    assert 'class="inactive"' in html
    assert 'class="badge-inactive">inactive</span>' in html


def test_releases_link():
    pkg = PackageInfo(
        name="foo",
        default="1.0",
        versions=["1.0"],
        releases="https://example.com",
    )
    html = _render_package_rows([pkg])
    assert '<a href="https://example.com" class="pkg-name">foo</a>' in html


def test_no_releases_uses_span():
    pkg = PackageInfo(name="foo", default="1.0", versions=["1.0"])
    html = _render_package_rows([pkg])
    assert '<span class="pkg-name">foo</span>' in html


def test_toolchain_details_expansion():
    tc = ToolchainInfo(
        name="my-toolchain",
        default="1",
        versions=["1"],
        expansion={
            "1": [ToolchainComponent(name="tool", version="1.0.0")]
        },
    )
    html = _render_toolchain_rows([tc])
    assert '<details class="tc-details">' in html
    assert "<code>tool</code>" in html
    assert "1.0.0" in html


def test_render_html_produces_valid_structure():
    pkg = PackageInfo(name="test", default="1.0", versions=["1.0"])
    tc = ToolchainInfo(
        name="test-toolchain",
        default="1",
        versions=["1"],
        expansion={"1": [ToolchainComponent(name="test", version="1.0")]},
    )
    html = render_html([pkg], [tc], template=INLINE_TEMPLATE, css=INLINE_CSS)
    assert "<!DOCTYPE html>" in html
    assert "<title>Toolbox Package Registry</title>" in html
    assert '<div class="stat-value">1</div>' in html  # num_packages
    assert "body { color: black; }" in html  # css injected verbatim
    assert "test-toolchain" in html
