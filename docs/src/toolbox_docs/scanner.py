"""Scan packages directory and build package/toolchain metadata."""

import json
from pathlib import Path

from .models import PackageInfo, ToolchainComponent, ToolchainInfo
from .sorting import version_key


def sorted_version_names(data: dict) -> list[str]:
    """The version keys of a data.json (all keys except ``_meta``), newest first."""
    return sorted(
        (k for k in data if k != "_meta"),
        key=version_key,
        reverse=True,
    )


def parse_toolchain_data(
    data: dict,
) -> tuple[str, list[str], dict[str, list[ToolchainComponent]]]:
    """Extract toolchain versions and their pinned components from data.json.

    Returns (default, version_names, {version: [ToolchainComponent, ...]}).
    """
    meta = data.get("_meta", {})
    default = meta.get("default", "")

    version_names = sorted_version_names(data)
    version_map: dict[str, list[ToolchainComponent]] = {
        ver: [
            ToolchainComponent(name=pkg, version=pin)
            for pkg, pin in sorted(data[ver].items())
        ]
        for ver in version_names
    }

    return default, version_names, version_map


def is_skill_bundle(data: dict) -> bool:
    """Whether a data.json describes a skill bundle.

    A skill bundle declares itself with ``_meta.fromClaudePlugin`` — the same
    field the Nix ``buildSkillBundle`` reads. Presence of the key (regardless
    of its boolean value) is the marker; plain packages never carry it. This is
    the pure, data-driven signal that classify_entry can observe (it cannot see
    which Nix builder a package uses). See docs/adr/0001.
    """
    return "fromClaudePlugin" in data.get("_meta", {})


def classify_entry(name: str, data: dict) -> PackageInfo | ToolchainInfo:
    """Classify one package entry from its name and parsed data.json.

    Pure: no filesystem access, dict in / model out. Mirrors the already-pure
    parse_toolchain_data seam so classification can be tested without an
    on-disk tree.

    A directory whose name ends in ``-toolchain`` is a toolchain; everything
    else is a package. Skill bundles are recognized (see :func:`is_skill_bundle`)
    and folded into the package list. See docs/adr/0001 for why the name suffix —
    not the Nix builder — is the toolchain rule, and why skill bundles fold in.
    """
    if name.endswith("-toolchain"):
        default, version_names, version_map = parse_toolchain_data(data)
        return ToolchainInfo(
            name=name,
            default=default,
            versions=version_names,
            expansion=version_map,
        )

    meta = data.get("_meta", {})
    return PackageInfo(
        name=name,
        default=meta.get("default", ""),
        versions=sorted_version_names(data),
        releases=meta.get("releases", ""),
        inactive=meta.get("inactive", False),
        skill_bundle=is_skill_bundle(data),
    )


def scan_packages(
    packages_dir: Path,
) -> tuple[list[PackageInfo], list[ToolchainInfo]]:
    """Scan a packages directory and return classified package and toolchain info.

    A thin filesystem walk: find each ``data.json``, parse it, and delegate
    classification to the pure :func:`classify_entry`.
    """
    packages: list[PackageInfo] = []
    toolchains: list[ToolchainInfo] = []

    for pkg_dir in sorted(packages_dir.iterdir()):
        if not pkg_dir.is_dir():
            continue

        data_json = pkg_dir / "data.json"
        if not data_json.exists():
            continue

        data = json.loads(data_json.read_text())
        entry = classify_entry(pkg_dir.name, data)
        if isinstance(entry, ToolchainInfo):
            toolchains.append(entry)
        else:
            packages.append(entry)

    return packages, toolchains
