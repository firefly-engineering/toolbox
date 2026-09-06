"""Shared test fixtures."""

import json
from pathlib import Path

import pytest


def manifest_entry(
    kind="package", default="1.2.0", versions=None, releases="", inactive=False,
    components=None, systems=("x86_64-linux", "aarch64-darwin"),
):
    """One manifest entry, in the shape `nix eval .#manifest` emits."""
    versions = versions or ["1.2.0", "1.1.0"]
    return {
        "kind": kind,
        "default": default,
        "releases": releases,
        "inactive": inactive,
        "components": components,
        "versions": {v: {"systems": list(systems)} for v in versions},
    }


@pytest.fixture
def manifest() -> dict:
    """A minimal registry manifest with one of each kind the registry stamps."""
    return {
        "packages": {
            "mypkg": manifest_entry(releases="https://example.com/releases"),
            "my-skills": manifest_entry(kind="skill-bundle", versions=["1.2.0"]),
            "my-toolchain": manifest_entry(
                kind="toolchain",
                default="2",
                versions=["2", "1"],
                components={"2": {"mypkg": "1.2.0"}, "1": {"mypkg": "1.1.0"}},
            ),
        }
    }


@pytest.fixture
def manifest_file(tmp_path: Path, manifest: dict) -> Path:
    path = tmp_path / "manifest.json"
    path.write_text(json.dumps(manifest))
    return path
