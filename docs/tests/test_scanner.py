"""Tests for scanner module."""

import json
from pathlib import Path

from toolbox_docs.scanner import parse_toolchain_data, scan_packages


def test_scan_classifies_packages_and_toolchains(tmp_packages: Path):
    packages, toolchains = scan_packages(tmp_packages)
    assert len(packages) == 1
    assert len(toolchains) == 1
    assert packages[0].name == "mypkg"
    assert toolchains[0].name == "my-toolchain"


def test_package_versions_sorted_descending(tmp_packages: Path):
    packages, _ = scan_packages(tmp_packages)
    assert packages[0].versions == ["1.2.0", "1.1.0"]


def test_package_metadata(tmp_packages: Path):
    packages, _ = scan_packages(tmp_packages)
    pkg = packages[0]
    assert pkg.default == "1.2.0"
    assert pkg.releases == "https://example.com/releases"
    assert pkg.inactive is False


def test_inactive_flag(tmp_path: Path):
    pkg = tmp_path / "packages" / "old"
    pkg.mkdir(parents=True)
    (pkg / "data.json").write_text(
        json.dumps(
            {
                "_meta": {"default": "1.0.0", "inactive": True},
                "1.0.0": {"sha256": "sha256-xxx"},
            }
        )
    )
    packages, _ = scan_packages(tmp_path / "packages")
    assert packages[0].inactive is True


def test_skips_non_dirs_and_missing_data(tmp_path: Path):
    pkgs = tmp_path / "packages"
    pkgs.mkdir()
    (pkgs / "not-a-dir.txt").write_text("ignored")
    empty_dir = pkgs / "no-data"
    empty_dir.mkdir()
    packages, toolchains = scan_packages(pkgs)
    assert packages == []
    assert toolchains == []


def test_toolchain_expansion(tmp_packages: Path):
    _, toolchains = scan_packages(tmp_packages)
    tc = toolchains[0]
    assert tc.default == "2"
    assert tc.versions == ["2", "1"]
    assert len(tc.expansion["2"]) == 1
    assert tc.expansion["2"][0].name == "mypkg"
    assert tc.expansion["2"][0].version == "1.2.0"


def test_parse_toolchain_data_sorts_components():
    data = {
        "_meta": {"default": "1"},
        "1": {"zebra": "1.0", "alpha": "2.0"},
    }
    _, _, version_map = parse_toolchain_data(data)
    assert version_map["1"][0].name == "alpha"
    assert version_map["1"][1].name == "zebra"
