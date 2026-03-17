"""Version sorting utilities."""

import re


def version_key(v: str) -> list[int | str]:
    """Split a version string into a list of ints and strings for natural sorting."""
    parts = re.split(r"(\d+)", v)
    return [int(p) if p.isdigit() else p for p in parts]
