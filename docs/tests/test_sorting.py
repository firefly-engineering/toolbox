"""Tests for version_key sorting."""

from toolbox_docs.sorting import version_key


def test_natural_ordering():
    versions = ["1.9.0", "1.10.0", "1.2.0"]
    result = sorted(versions, key=version_key)
    assert result == ["1.2.0", "1.9.0", "1.10.0"]


def test_reverse_ordering():
    versions = ["1.2.0", "1.10.0", "1.9.0"]
    result = sorted(versions, key=version_key, reverse=True)
    assert result == ["1.10.0", "1.9.0", "1.2.0"]


def test_v_prefix():
    versions = ["v1.5.1", "v1.4.0", "v1.10.0"]
    result = sorted(versions, key=version_key)
    assert result == ["v1.4.0", "v1.5.1", "v1.10.0"]


def test_date_versions():
    versions = ["2025-12-01", "2026-03-15"]
    result = sorted(versions, key=version_key)
    assert result == ["2025-12-01", "2026-03-15"]


def test_prerelease():
    versions = ["0.5.0-pre96-test", "0.5.0"]
    result = sorted(versions, key=version_key)
    assert result == ["0.5.0", "0.5.0-pre96-test"]


def test_single_digit_versions():
    versions = ["2", "1", "10"]
    result = sorted(versions, key=version_key)
    assert result == ["1", "2", "10"]
