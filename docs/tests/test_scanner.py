"""Tests for scanner module."""

import json
from pathlib import Path

import pytest

from toolbox_docs.models import PackageInfo, ToolchainInfo
from toolbox_docs.scanner import (
    classify_entry,
    is_skill_bundle,
    parse_toolchain_data,
    resolve_data_from,
    scan_packages,
)

# --- classify_entry: pure classification, dicts in / models out --------------


def test_classify_package():
    data = {
        "_meta": {"default": "1.2.0", "releases": "https://example.com/releases"},
        "1.2.0": {"sha256": "sha256-aaa"},
        "1.1.0": {"sha256": "sha256-bbb"},
    }
    entry = classify_entry("mypkg", data)
    assert isinstance(entry, PackageInfo)
    assert entry.name == "mypkg"
    assert entry.default == "1.2.0"
    assert entry.releases == "https://example.com/releases"
    assert entry.inactive is False


def test_classify_package_versions_sorted_descending():
    data = {
        "_meta": {"default": "1.2.0"},
        "1.1.0": {"sha256": "sha256-bbb"},
        "1.2.0": {"sha256": "sha256-aaa"},
    }
    entry = classify_entry("mypkg", data)
    assert entry.versions == ["1.2.0", "1.1.0"]


def test_classify_inactive_flag():
    data = {
        "_meta": {"default": "1.0.0", "inactive": True},
        "1.0.0": {"sha256": "sha256-xxx"},
    }
    entry = classify_entry("old", data)
    assert isinstance(entry, PackageInfo)
    assert entry.inactive is True


def test_classify_toolchain():
    data = {
        "_meta": {"default": "2"},
        "2": {"mypkg": "1.2.0"},
        "1": {"mypkg": "1.1.0"},
    }
    entry = classify_entry("my-toolchain", data)
    assert isinstance(entry, ToolchainInfo)
    assert entry.name == "my-toolchain"
    assert entry.default == "2"
    assert entry.versions == ["2", "1"]
    assert entry.expansion["2"][0].name == "mypkg"
    assert entry.expansion["2"][0].version == "1.2.0"


def test_classify_skill_bundle_folds_into_package():
    data = {
        "_meta": {
            "default": "1.1.0",
            "releases": "https://github.com/mattpocock/skills/releases",
            "fromClaudePlugin": True,
        },
        "1.1.0": {"owner": "mattpocock", "repo": "skills", "rev": "abc", "sha256": "sha256-x"},
    }
    entry = classify_entry("mattpocock-skills", data)
    # Folded into packages (not its own category) per docs/adr/0001 ...
    assert isinstance(entry, ToolchainInfo) is False
    assert isinstance(entry, PackageInfo)
    # ... but recognized explicitly rather than silently treated as a plain package.
    assert entry.skill_bundle is True
    assert entry.default == "1.1.0"
    assert entry.releases == "https://github.com/mattpocock/skills/releases"


def test_classify_plain_package_is_not_skill_bundle():
    data = {"_meta": {"default": "1.0.0"}, "1.0.0": {"sha256": "sha256-x"}}
    entry = classify_entry("mypkg", data)
    assert entry.skill_bundle is False


def test_is_skill_bundle_marker():
    assert is_skill_bundle({"_meta": {"fromClaudePlugin": True}}) is True
    # Presence of the key is the marker, regardless of value.
    assert is_skill_bundle({"_meta": {"fromClaudePlugin": False}}) is True
    assert is_skill_bundle({"_meta": {"default": "1.0.0"}}) is False
    assert is_skill_bundle({}) is False


def test_parse_toolchain_data_sorts_components():
    data = {
        "_meta": {"default": "1"},
        "1": {"zebra": "1.0", "alpha": "2.0"},
    }
    _, _, version_map = parse_toolchain_data(data)
    assert version_map["1"][0].name == "alpha"
    assert version_map["1"][1].name == "zebra"


# --- resolve_data_from: pure merge of a pointer data.json with its source ----


def test_resolve_data_from_takes_versions_from_source():
    local = {"_meta": {"dataFrom": "tuicr"}}
    source = {
        "_meta": {"default": "0.20.0", "releases": "https://example.com/releases"},
        "0.20.0": {"sha256": "sha256-a"},
        "0.19.1": {"sha256": "sha256-b"},
    }
    merged = resolve_data_from(local, source)
    assert merged["0.20.0"] == {"sha256": "sha256-a"}
    assert merged["0.19.1"] == {"sha256": "sha256-b"}
    assert merged["_meta"]["default"] == "0.20.0"
    assert merged["_meta"]["releases"] == "https://example.com/releases"


def test_resolve_data_from_local_meta_wins():
    local = {"_meta": {"dataFrom": "tuicr", "releases": "https://local/releases"}}
    source = {"_meta": {"default": "1.0.0", "releases": "https://source/releases"}}
    merged = resolve_data_from(local, source)
    # Local states what is true of the pointer package ...
    assert merged["_meta"]["releases"] == "https://local/releases"
    # ... and inherits the rest from the source it shares a pin with.
    assert merged["_meta"]["default"] == "1.0.0"


def test_resolve_data_from_drops_the_pointer_key():
    merged = resolve_data_from({"_meta": {"dataFrom": "tuicr"}}, {"_meta": {"default": "1.0.0"}})
    assert "dataFrom" not in merged["_meta"]


def test_resolve_data_from_carries_skill_bundle_marker():
    """The marker lives locally: the shared source data.json is a plain package."""
    local = {"_meta": {"dataFrom": "tuicr", "fromClaudePlugin": False}}
    source = {"_meta": {"default": "1.0.0"}, "1.0.0": {"sha256": "sha256-x"}}
    entry = classify_entry("tuicr-skills", resolve_data_from(local, source))
    assert entry.skill_bundle is True
    assert entry.versions == ["1.0.0"]


# --- scan_packages: thin filesystem walk over classify_entry -----------------


def test_scan_walk_classifies_packages_and_toolchains(tmp_packages: Path):
    packages, toolchains = scan_packages(tmp_packages)
    assert [p.name for p in packages] == ["mypkg"]
    assert [t.name for t in toolchains] == ["my-toolchain"]


def test_scan_walk_skips_non_dirs_and_missing_data(tmp_path: Path):
    pkgs = tmp_path / "packages"
    pkgs.mkdir()
    (pkgs / "not-a-dir.txt").write_text("ignored")
    empty_dir = pkgs / "no-data"
    empty_dir.mkdir()
    packages, toolchains = scan_packages(pkgs)
    assert packages == []
    assert toolchains == []


def test_scan_walk_follows_data_from_pointer(tmp_path: Path):
    pkgs = tmp_path / "packages"
    (pkgs / "src").mkdir(parents=True)
    (pkgs / "src" / "data.json").write_text(
        json.dumps(
            {
                "_meta": {"default": "2.0.0", "releases": "https://example.com/releases"},
                "2.0.0": {"sha256": "sha256-a"},
                "1.0.0": {"sha256": "sha256-b"},
            }
        )
    )
    (pkgs / "src-skills").mkdir()
    (pkgs / "src-skills" / "data.json").write_text(
        json.dumps({"_meta": {"dataFrom": "src", "fromClaudePlugin": False}})
    )

    packages, _ = scan_packages(pkgs)
    by_name = {p.name: p for p in packages}
    assert set(by_name) == {"src", "src-skills"}
    assert by_name["src-skills"].versions == ["2.0.0", "1.0.0"]
    assert by_name["src-skills"].default == "2.0.0"
    assert by_name["src-skills"].releases == "https://example.com/releases"
    assert by_name["src-skills"].skill_bundle is True
    assert by_name["src"].skill_bundle is False


def test_scan_walk_dangling_data_from_is_an_error(tmp_path: Path):
    pkgs = tmp_path / "packages"
    (pkgs / "orphan").mkdir(parents=True)
    (pkgs / "orphan" / "data.json").write_text(json.dumps({"_meta": {"dataFrom": "gone"}}))
    with pytest.raises(FileNotFoundError, match="orphan"):
        scan_packages(pkgs)


def test_scan_walk_reads_data_json(tmp_path: Path):
    pkg = tmp_path / "packages" / "solo"
    pkg.mkdir(parents=True)
    (pkg / "data.json").write_text(
        json.dumps(
            {
                "_meta": {"default": "1.0.0"},
                "1.0.0": {"sha256": "sha256-xxx"},
            }
        )
    )
    packages, _ = scan_packages(tmp_path / "packages")
    assert [p.name for p in packages] == ["solo"]
    assert packages[0].default == "1.0.0"
