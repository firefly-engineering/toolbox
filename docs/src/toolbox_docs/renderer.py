"""Render HTML documentation from package and toolchain metadata."""

from pathlib import Path
from string import Template

from .models import PackageInfo, ToolchainInfo


def _render_package_rows(packages: list[PackageInfo]) -> str:
    rows = ""
    for pkg in packages:
        versions_html = ", ".join(
            f'<span class="version{" default" if v == pkg.default else ""}">{v}</span>'
            for v in pkg.versions
        )
        if pkg.releases:
            name_html = f'<a href="{pkg.releases}" class="pkg-name">{pkg.name}</a>'
        else:
            name_html = f'<span class="pkg-name">{pkg.name}</span>'
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
                f'<tr><td><code>{c.name}</code></td><td>{c.version}</td></tr>'
                for c in components
            )
            versions_html += f"""<details class="tc-details">
          <summary><span class="version{" default" if is_default else ""}">{ver}</span></summary>
          <table class="tc-expansion"><tbody>{comp_rows}</tbody></table>
        </details>"""
        rows += f"""      <tr>
        <td class="pkg-name">{tc.name}</td>
        <td>{versions_html}</td>
      </tr>
"""
    return rows


def render_html(packages: list[PackageInfo], toolchains: list[ToolchainInfo]) -> str:
    """Render the full HTML page from package and toolchain metadata."""
    assets_dir = Path(__file__).parent / "assets"
    templates_dir = Path(__file__).parent.parent.parent / "templates"

    css = (assets_dir / "style.css").read_text()
    template_str = (templates_dir / "index.html.tmpl").read_text()

    package_rows = _render_package_rows(packages)
    toolchain_rows = _render_toolchain_rows(toolchains)
    total_versions = sum(len(p.versions) for p in packages)

    tmpl = Template(template_str)
    return tmpl.substitute(
        css=css,
        num_packages=len(packages),
        total_versions=total_versions,
        num_toolchains=len(toolchains),
        package_rows=package_rows,
        toolchain_rows=toolchain_rows,
    )
