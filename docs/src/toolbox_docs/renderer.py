"""Render HTML documentation from package and toolchain metadata."""

from html import escape
from string import Template

from .models import PackageInfo, ToolchainInfo


def _version_span(version: str, is_default: bool) -> str:
    default_class = " default" if is_default else ""
    return f'<span class="version{default_class}">{escape(version)}</span>'


def _render_package_rows(packages: list[PackageInfo]) -> str:
    rows = ""
    for pkg in packages:
        versions_html = ", ".join(
            _version_span(v, v == pkg.default) for v in pkg.versions
        )
        if pkg.releases:
            name_html = (
                f'<a href="{escape(pkg.releases)}" class="pkg-name">{escape(pkg.name)}</a>'
            )
        else:
            name_html = f'<span class="pkg-name">{escape(pkg.name)}</span>'
        if pkg.inactive:
            name_html += ' <span class="badge-inactive">inactive</span>'
        row_class = ' class="inactive"' if pkg.inactive else ""
        rows += f"""      <tr{row_class}>
        <td>{name_html}</td>
        <td>{versions_html}</td>
      </tr>
"""
    return rows


def _render_toolchain_rows(toolchains: list[ToolchainInfo]) -> str:
    rows = ""
    for tc in toolchains:
        versions_html = ""
        for ver in tc.versions:
            is_default = ver == tc.default
            components = tc.expansion.get(ver, [])
            comp_rows = "".join(
                f'<tr><td><code>{escape(c.name)}</code></td><td>{escape(c.version)}</td></tr>'
                for c in components
            )
            versions_html += f"""<details class="tc-details">
          <summary>{_version_span(ver, is_default)}</summary>
          <table class="tc-expansion"><tbody>{comp_rows}</tbody></table>
        </details>"""
        rows += f"""      <tr>
        <td class="pkg-name">{escape(tc.name)}</td>
        <td>{versions_html}</td>
      </tr>
"""
    return rows


def render_html(
    packages: list[PackageInfo],
    toolchains: list[ToolchainInfo],
    *,
    template: str,
    css: str,
) -> str:
    """Render the full HTML page from package and toolchain metadata.

    ``template`` and ``css`` are supplied by the caller so this transform is
    pure — it performs no filesystem access. The ``__main__`` edge loads the
    asset files and injects them.
    """
    package_rows = _render_package_rows(packages)
    toolchain_rows = _render_toolchain_rows(toolchains)
    total_versions = sum(len(p.versions) for p in packages)

    tmpl = Template(template)
    return tmpl.substitute(
        css=css,
        num_packages=len(packages),
        total_versions=total_versions,
        num_toolchains=len(toolchains),
        package_rows=package_rows,
        toolchain_rows=toolchain_rows,
    )
