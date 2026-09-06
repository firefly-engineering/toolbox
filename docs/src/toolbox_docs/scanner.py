"""Turn the registry manifest into the models the renderer draws.

The registry publishes what it knows about itself — see ``nix eval .#manifest``
and ``lib/manifest.nix``. This module used to walk ``packages/*/data.json`` and
reconstruct that: "toolchain" from a ``-toolchain`` name suffix, "skill bundle"
from the presence of a ``_meta.fromClaudePlugin`` key, a package's existence
from having a data file at all. Each was a guess standing in for a decision the
Nix builder had already made, and each needed an ADR when it went wrong
(docs/adr/0001, 0002, 0003). Now the builder states it and this reads it.

Pure: dicts in, models out. The manifest is loaded at the ``__main__`` edge.
"""

import json
from pathlib import Path

from .models import PackageInfo, ToolchainComponent, ToolchainInfo
from .sorting import version_key


def load_manifest(path: Path) -> dict:
    """Read a manifest produced by ``nix eval --json .#manifest``."""
    manifest = json.loads(Path(path).read_text())
    if "packages" not in manifest:
        raise ValueError(f"{path}: not a registry manifest (no 'packages' key)")
    return manifest


def sorted_version_names(entry: dict) -> list[str]:
    """A manifest entry's version names, newest first.

    The manifest deliberately leaves version order unspecified — ordering is
    presentation, so the natural-sort semantics live here rather than in Nix.
    """
    return sorted(entry["versions"], key=version_key, reverse=True)


def build_models(
    manifest: dict,
) -> tuple[list[PackageInfo], list[ToolchainInfo], list[PackageInfo]]:
    """Split the manifest into the three lists the renderer draws.

    ``kind`` comes from the builder that assembled the package, so there is no
    classification to do here — only a routing of stamped entries. Skill bundles
    get their own list, and so their own section (docs/adr/0005); they share
    ``PackageInfo`` because they have the same shape, and the list they land in
    is what marks them.
    """
    packages: list[PackageInfo] = []
    toolchains: list[ToolchainInfo] = []
    skill_bundles: list[PackageInfo] = []

    for name, entry in sorted(manifest["packages"].items()):
        versions = sorted_version_names(entry)

        if entry["kind"] == "toolchain":
            components = entry.get("components") or {}
            toolchains.append(
                ToolchainInfo(
                    name=name,
                    default=entry["default"],
                    versions=versions,
                    expansion={
                        ver: [
                            ToolchainComponent(name=pkg, version=pin)
                            for pkg, pin in sorted(components.get(ver, {}).items())
                        ]
                        for ver in versions
                    },
                )
            )
        else:
            info = PackageInfo(
                name=name,
                default=entry["default"],
                versions=versions,
                releases=entry.get("releases") or "",
                inactive=entry.get("inactive", False),
            )
            if entry["kind"] == "skill-bundle":
                skill_bundles.append(info)
            else:
                packages.append(info)

    return packages, toolchains, skill_bundles
