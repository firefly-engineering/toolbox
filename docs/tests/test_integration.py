"""Integration tests: manifest in, HTML out."""

from pathlib import Path

from toolbox_docs.__main__ import load_assets
from toolbox_docs.renderer import render_html
from toolbox_docs.scanner import build_models, load_manifest


def test_end_to_end_from_a_manifest(manifest_file: Path):
    """Generate HTML from a fixture manifest and verify basic structure."""
    packages, toolchains = build_models(load_manifest(manifest_file))
    template, css = load_assets()
    html = render_html(packages, toolchains, template=template, css=css)
    assert "<!DOCTYPE html>" in html
    assert "mypkg" in html
    assert "my-toolchain" in html
    assert '<div class="stat-value">1</div>' in html
