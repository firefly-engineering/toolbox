"""Shared test fixtures."""

import json
from pathlib import Path

import pytest


@pytest.fixture
def tmp_packages(tmp_path: Path) -> Path:
    """Create a minimal packages directory with one package and one toolchain."""
    pkg = tmp_path / "packages" / "mypkg"
    pkg.mkdir(parents=True)
    (pkg / "data.json").write_text(
        json.dumps(
            {
                "_meta": {"default": "1.2.0", "releases": "https://example.com/releases"},
                "1.2.0": {"sha256": "sha256-aaa"},
                "1.1.0": {"sha256": "sha256-bbb"},
            }
        )
    )

    tc = tmp_path / "packages" / "my-toolchain"
    tc.mkdir(parents=True)
    (tc / "data.json").write_text(
        json.dumps(
            {
                "_meta": {"default": "2"},
                "2": {"mypkg": "1.2.0"},
                "1": {"mypkg": "1.1.0"},
            }
        )
    )

    return tmp_path / "packages"


@pytest.fixture
def repo_root() -> Path:
    """Return the real repo root for integration tests."""
    return Path(__file__).resolve().parent.parent.parent
