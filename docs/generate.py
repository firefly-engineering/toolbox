#!/usr/bin/env python3
"""Generate GitHub Pages documentation from the toolbox package registry."""

import json
from pathlib import Path


def parse_toolchain_data(
    data: dict,
) -> tuple[str, list[str], dict[str, list[dict]]]:
    """Extract toolchain versions and their pinned components from data.json.

    Returns (default, version_names, {version: [{name, version}, ...]}).
    """
    meta = data.get("_meta", {})
    default = meta.get("default", "")

    version_names = []
    version_map = {}
    for ver, ver_data in sorted(
        ((k, v) for k, v in data.items() if k != "_meta"),
        key=lambda x: x[0],
        reverse=True,
    ):
        version_names.append(ver)
        version_map[ver] = [
            {"name": pkg, "version": pin}
            for pkg, pin in sorted(ver_data.items())
        ]

    return default, version_names, version_map


def main():
    repo_root = Path(__file__).resolve().parent.parent
    packages_dir = repo_root / "packages"
    out_dir = repo_root / "docs" / "_site"
    out_dir.mkdir(parents=True, exist_ok=True)

    packages = []
    toolchains = []

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
                {
                    "name": name,
                    "default": default,
                    "versions": version_names,
                    "expansion": version_map,
                }
            )
        else:
            default_version = meta.get("default", "")
            releases_url = meta.get("releases", "")
            versions = sorted(
                [k for k in data if k != "_meta"],
                key=lambda v: v,
                reverse=True,
            )
            packages.append(
                {
                    "name": name,
                    "default": default_version,
                    "versions": versions,
                    "releases": releases_url,
                }
            )

    html = render_html(packages, toolchains)
    (out_dir / "index.html").write_text(html)
    print(
        f"Generated docs with {len(packages)} packages and {len(toolchains)} toolchains"
    )


def render_html(packages: list[dict], toolchains: list[dict]) -> str:
    package_rows = ""
    for pkg in packages:
        versions_html = ", ".join(
            f'<span class="version{" default" if v == pkg["default"] else ""}">{v}</span>'
            for v in pkg["versions"]
        )
        if pkg["releases"]:
            name_html = f'<a href="{pkg["releases"]}" class="pkg-name">{pkg["name"]}</a>'
        else:
            name_html = f'<span class="pkg-name">{pkg["name"]}</span>'
        package_rows += f"""      <tr>
        <td>{name_html}</td>
        <td>{versions_html}</td>
      </tr>
"""

    toolchain_rows = ""
    for tc in toolchains:
        versions_html = ""
        for ver in tc["versions"]:
            is_default = ver == tc["default"]
            components = tc["expansion"].get(ver, [])
            comp_rows = "".join(
                f'<tr><td><code>{c["name"]}</code></td><td>{c["version"]}</td></tr>'
                for c in components
            )
            versions_html += f"""<details class="tc-details">
          <summary><span class="version{" default" if is_default else ""}">{ver}</span></summary>
          <table class="tc-expansion"><tbody>{comp_rows}</tbody></table>
        </details>"""
        toolchain_rows += f"""      <tr>
        <td class="pkg-name">{tc["name"]}</td>
        <td>{versions_html}</td>
      </tr>
"""

    total_versions = sum(len(p["versions"]) for p in packages)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Toolbox Package Registry</title>
  <style>
    :root {{
      --bg: #0d1117;
      --surface: #161b22;
      --border: #30363d;
      --text: #e6edf3;
      --text-muted: #8b949e;
      --accent: #58a6ff;
      --green: #3fb950;
    }}
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding: 2rem;
      max-width: 1100px;
      margin: 0 auto;
    }}
    h1 {{
      font-size: 2rem;
      margin-bottom: 0.25rem;
    }}
    .subtitle {{
      color: var(--text-muted);
      margin-bottom: 2rem;
      font-size: 1.1rem;
    }}
    .stats {{
      display: flex;
      gap: 2rem;
      margin-bottom: 2rem;
    }}
    .stat {{
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem 1.5rem;
    }}
    .stat-value {{
      font-size: 1.5rem;
      font-weight: 600;
      color: var(--accent);
    }}
    .stat-label {{
      color: var(--text-muted);
      font-size: 0.85rem;
    }}
    h2 {{
      font-size: 1.4rem;
      margin: 2rem 0 1rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid var(--border);
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      overflow: hidden;
    }}
    th {{
      text-align: left;
      padding: 0.75rem 1rem;
      background: var(--bg);
      color: var(--text-muted);
      font-size: 0.85rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }}
    td {{
      padding: 0.6rem 1rem;
      border-top: 1px solid var(--border);
    }}
    .pkg-name {{
      font-weight: 600;
      color: var(--accent);
      white-space: nowrap;
      text-decoration: none;
    }}
    a.pkg-name:hover {{
      text-decoration: underline;
    }}
    code {{
      background: var(--bg);
      padding: 0.15em 0.4em;
      border-radius: 4px;
      font-size: 0.9em;
    }}
    .version {{
      display: inline-block;
      background: var(--bg);
      padding: 0.1em 0.5em;
      border-radius: 4px;
      font-size: 0.85em;
      margin: 0.1em;
    }}
    .version.default {{
      background: rgba(63, 185, 80, 0.15);
      color: var(--green);
      font-weight: 600;
    }}
    .tc-details {{
      display: inline-block;
      margin: 0.1em;
    }}
    .tc-details summary {{
      cursor: pointer;
      list-style: none;
    }}
    .tc-details summary::-webkit-details-marker {{
      display: none;
    }}
    .tc-details summary .version::after {{
      content: " \u25b8";
      font-size: 0.7em;
      color: var(--text-muted);
      vertical-align: middle;
    }}
    .tc-details[open] summary .version::after {{
      content: " \u25be";
    }}
    .tc-expansion {{
      margin: 0.4em 0 0.2em 0.5em;
      background: var(--bg);
      border: 1px solid var(--border);
      font-size: 0.85em;
    }}
    .tc-expansion td {{
      padding: 0.25rem 0.6rem;
    }}
    footer {{
      margin-top: 3rem;
      padding-top: 1rem;
      border-top: 1px solid var(--border);
      color: var(--text-muted);
      font-size: 0.85rem;
    }}
    footer a {{
      color: var(--accent);
      text-decoration: none;
    }}
  </style>
</head>
<body>
  <h1>Toolbox</h1>
  <p class="subtitle">Self-contained package registry for <a href="https://github.com/firefly-engineering/turnkey" style="color: var(--accent); text-decoration: none;">turnkey</a></p>

  <div class="stats">
    <div class="stat">
      <div class="stat-value">{len(packages)}</div>
      <div class="stat-label">Packages</div>
    </div>
    <div class="stat">
      <div class="stat-value">{total_versions}</div>
      <div class="stat-label">Versions</div>
    </div>
    <div class="stat">
      <div class="stat-value">{len(toolchains)}</div>
      <div class="stat-label">Toolchains</div>
    </div>
  </div>

  <h2>Packages</h2>
  <table>
    <thead>
      <tr>
        <th>Package</th>
        <th>Versions</th>
      </tr>
    </thead>
    <tbody>
{package_rows}    </tbody>
  </table>

  <h2>Toolchain Meta-packages</h2>
  <table>
    <thead>
      <tr>
        <th>Toolchain</th>
        <th>Versions</th>
      </tr>
    </thead>
    <tbody>
{toolchain_rows}    </tbody>
  </table>

  <footer>
    <p>Generated from <a href="https://github.com/firefly-engineering/toolbox">firefly-engineering/toolbox</a>. Default versions shown in <span style="color: var(--green);">green</span>.</p>
  </footer>
</body>
</html>
"""


if __name__ == "__main__":
    main()
