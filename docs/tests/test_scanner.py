"""Tests for the manifest -> models transform."""

import json
from pathlib import Path

import pytest

from toolbox_docs.models import PackageInfo, ToolchainInfo
from toolbox_docs.scanner import build_models, load_manifest, sorted_version_names

from .conftest import manifest_entry

# --- build_models: pure, manifest in / models out ---------------------------


def _one(entry, name="mypkg"):
    return build_models({"packages": {name: entry}})


def test_package_fields_come_from_the_manifest():
    packages, toolchains, bundles = _one(
        manifest_entry(releases="https://example.com/releases")
    )
    assert (toolchains, bundles) == ([], [])
    (pkg,) = packages
    assert isinstance(pkg, PackageInfo)
    assert pkg.name == "mypkg"
    assert pkg.default == "1.2.0"
    assert pkg.releases == "https://example.com/releases"
    assert pkg.inactive is False


def test_versions_are_sorted_newest_first():
    """The manifest leaves order unspecified; ordering is this module's job."""
    entry = manifest_entry(versions=["1.1.0", "1.10.0", "1.2.0"])
    (pkg,), _, _ = _one(entry)
    assert pkg.versions == ["1.10.0", "1.2.0", "1.1.0"]


def test_inactive_flag_is_carried():
    (pkg,), _, _ = _one(manifest_entry(inactive=True))
    assert pkg.inactive is True


def test_missing_releases_becomes_empty_string():
    """Nix emits null for a package with no _meta.releases; the renderer wants ''."""
    entry = manifest_entry()
    entry["releases"] = None
    (pkg,), _, _ = _one(entry)
    assert pkg.releases == ""


# --- kind routing: the classification the builder already made --------------


def test_toolchain_kind_routes_to_toolchain_list():
    entry = manifest_entry(
        kind="toolchain", default="2", versions=["2", "1"],
        components={"2": {"mypkg": "1.2.0"}, "1": {"mypkg": "1.1.0"}},
    )
    packages, toolchains, bundles = _one(entry, name="my-toolchain")
    assert (packages, bundles) == ([], [])
    (tc,) = toolchains
    assert isinstance(tc, ToolchainInfo)
    assert tc.versions == ["2", "1"]
    assert [(c.name, c.version) for c in tc.expansion["2"]] == [("mypkg", "1.2.0")]


def test_toolchain_components_are_sorted():
    entry = manifest_entry(
        kind="toolchain", default="1", versions=["1"],
        components={"1": {"zebra": "1.0", "alpha": "2.0"}},
    )
    _, (tc,), _ = _one(entry, name="x-toolchain")
    assert [c.name for c in tc.expansion["1"]] == ["alpha", "zebra"]


def test_skill_bundle_routes_to_its_own_list():
    """Bundles get their own section, so their own list (docs/adr/0005)."""
    packages, toolchains, bundles = _one(
        manifest_entry(kind="skill-bundle", releases="https://example.com/releases"),
        name="some-skills",
    )
    assert (packages, toolchains) == ([], [])
    (bundle,) = bundles
    assert isinstance(bundle, PackageInfo)
    assert bundle.name == "some-skills"
    assert bundle.releases == "https://example.com/releases"


def test_a_toolchain_is_not_decided_by_its_name():
    """The old rule was `name.endswith('-toolchain')`; kind is what decides now."""
    packages, toolchains, bundles = _one(
        manifest_entry(kind="package"), name="fake-toolchain"
    )
    assert (toolchains, bundles) == ([], [])
    assert packages[0].name == "fake-toolchain"


def test_entries_are_ordered_by_name():
    packages, _, _ = build_models(
        {"packages": {"zebra": manifest_entry(), "alpha": manifest_entry()}}
    )
    assert [p.name for p in packages] == ["alpha", "zebra"]


# --- load_manifest: the one bit of I/O --------------------------------------


def test_load_manifest_reads_json(manifest_file: Path):
    assert "mypkg" in load_manifest(manifest_file)["packages"]


def test_load_manifest_rejects_a_non_manifest(tmp_path: Path):
    path = tmp_path / "junk.json"
    path.write_text(json.dumps({"nope": {}}))
    with pytest.raises(ValueError, match="not a registry manifest"):
        load_manifest(path)


def test_sorted_version_names_is_descending():
    assert sorted_version_names(manifest_entry(versions=["1.1.0", "1.2.0"])) == [
        "1.2.0",
        "1.1.0",
    ]
