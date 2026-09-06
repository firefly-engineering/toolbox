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
<div class="stat-value">$num_skill_bundles</div>
<tbody>$package_rows</tbody>
<tbody>$toolchain_rows</tbody>
<tbody>$skill_bundle_rows</tbody>
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


def test_package_rows_escape_html_special_chars():
    pkg = PackageInfo(
        name="a<b>&c",
        default='1"<v>',
        versions=['1"<v>'],
        releases="https://example.com/?a=1&b=2<x>",
    )
    html = _render_package_rows([pkg])
    # Raw special characters must not leak into the markup.
    assert "a<b>&c" not in html
    assert "&lt;b&gt;" in html and "&amp;c" in html
    # Attribute value is escaped (quotes included).
    assert 'href="https://example.com/?a=1&amp;b=2&lt;x&gt;"' in html
    # The version string is escaped in text content.
    assert "1&quot;&lt;v&gt;" in html


def test_toolchain_rows_escape_html_special_chars():
    tc = ToolchainInfo(
        name="tc<&>",
        default="1",
        versions=["1<&>"],
        expansion={"1<&>": [ToolchainComponent(name="c<&>", version="v<&>")]},
    )
    html = _render_toolchain_rows([tc])
    assert "tc<&>" not in html
    assert "tc&lt;&amp;&gt;" in html
    assert "<code>c&lt;&amp;&gt;</code>" in html
    assert "v&lt;&amp;&gt;" in html


def test_render_html_produces_valid_structure():
    pkg = PackageInfo(name="test", default="1.0", versions=["1.0"])
    tc = ToolchainInfo(
        name="test-toolchain",
        default="1",
        versions=["1"],
        expansion={"1": [ToolchainComponent(name="test", version="1.0")]},
    )
    bundle = PackageInfo(name="test-skills", default="1.0", versions=["1.0"])
    html = render_html(
        [pkg], [tc], [bundle], template=INLINE_TEMPLATE, css=INLINE_CSS
    )
    assert "<!DOCTYPE html>" in html
    assert "<title>Toolbox Package Registry</title>" in html
    assert '<div class="stat-value">1</div>' in html  # num_packages
    assert "body { color: black; }" in html  # css injected verbatim
    assert "test-toolchain" in html
    assert "test-skills" in html


def test_bundle_versions_count_toward_the_versions_total():
    """A bundle version is as buildable as any other, so the headline counts it."""
    pkg = PackageInfo(name="p", default="2.0", versions=["2.0", "1.0"])
    bundle = PackageInfo(name="b", default="3.0", versions=["3.0"])
    html = render_html([pkg], [], [bundle], template=INLINE_TEMPLATE, css=INLINE_CSS)
    assert '<div class="stat-value">3</div>' in html  # total_versions


def test_bundles_render_as_package_rows_in_their_own_section():
    bundle = PackageInfo(
        name="b", default="1.0", versions=["1.0"], releases="https://example.com"
    )
    html = render_html([], [], [bundle], template=INLINE_TEMPLATE, css=INLINE_CSS)
    assert html.count('<a href="https://example.com" class="pkg-name">b</a>') == 1
