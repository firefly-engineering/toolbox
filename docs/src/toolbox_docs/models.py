"""Data models for toolbox documentation."""

from dataclasses import dataclass, field


@dataclass
class PackageInfo:
    name: str
    default: str
    versions: list[str]
    releases: str = ""
    inactive: bool = False


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
