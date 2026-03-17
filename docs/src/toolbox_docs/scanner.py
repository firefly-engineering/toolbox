"""Scan packages directory and build package/toolchain metadata."""

import json
from pathlib import Path

from .models import PackageInfo, ToolchainComponent, ToolchainInfo
from .sorting import version_key


def parse_toolchain_data(
    data: dict,
) -> tuple[str, list[str], dict[str, list[ToolchainComponent]]]:
    """Extract toolchain versions and their pinned components from data.json.

    Returns (default, version_names, {version: [ToolchainComponent, ...]}).
    """
    meta = data.get("_meta", {})
    default = meta.get("default", "")

    version_names = []
    version_map: dict[str, list[ToolchainComponent]] = {}
    for ver, ver_data in sorted(
        ((k, v) for k, v in data.items() if k != "_meta"),
        key=lambda x: version_key(x[0]),
        reverse=True,
    ):
        version_names.append(ver)
        version_map[ver] = [
            ToolchainComponent(name=pkg, version=pin)
            for pkg, pin in sorted(ver_data.items())
        ]

    return default, version_names, version_map


def scan_packages(
    packages_dir: Path,
) -> tuple[list[PackageInfo], list[ToolchainInfo]]:
    """Scan a packages directory and return classified package and toolchain info."""
    packages: list[PackageInfo] = []
    toolchains: list[ToolchainInfo] = []

    for pkg_dir in sorted(packages_dir.iterdir()):
        if not pkg_dir.is_dir():
            continue

        name = pkg_dir.name
        data_json = pkg_dir / "data.json"

        if not data_json.exists():
            continue

        data = json.loads(data_json.read_text())
        meta = data.get("_meta", {})

        if name.endswith("-toolchain"):
            default, version_names, version_map = parse_toolchain_data(data)
            toolchains.append(
                ToolchainInfo(
                    name=name,
                    default=default,
                    versions=version_names,
                    expansion=version_map,
                )
            )
        else:
            default_version = meta.get("default", "")
            releases_url = meta.get("releases", "")
            inactive = meta.get("inactive", False)
            versions = sorted(
                [k for k in data if k != "_meta"],
                key=version_key,
                reverse=True,
            )
            packages.append(
                PackageInfo(
                    name=name,
                    default=default_version,
                    versions=versions,
                    releases=releases_url,
                    inactive=inactive,
                )
            )

    return packages, toolchains
