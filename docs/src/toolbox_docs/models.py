"""Data models for toolbox documentation."""

from dataclasses import dataclass, field


@dataclass
class PackageInfo:
    name: str
    default: str
    versions: list[str]
    releases: str = ""
    inactive: bool = False
    # True for skill bundles (data.json declares _meta.fromClaudePlugin). By
    # decision (docs/adr/0001) they are folded into the package list rather than
    # given their own docs section; this flag records the recognition so it is
    # explicit and tested rather than a silent fall-through.
    skill_bundle: bool = False


@dataclass
class ToolchainComponent:
    name: str
    version: str


@dataclass
class ToolchainInfo:
    name: str
    default: str
    versions: list[str]
    expansion: dict[str, list[ToolchainComponent]] = field(default_factory=dict)
