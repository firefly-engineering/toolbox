# 5. Skill bundles get their own docs section

Date: 2026-09-07

## Status

Accepted

Supersedes the rendering half of [ADR 0001](0001-docs-scanner-classification.md)
(its classification half was already superseded by
[ADR 0004](0004-registry-publishes-its-own-classification.md)).

## Context

[ADR 0001](0001-docs-scanner-classification.md) made two decisions about skill
bundles. It recognised them *explicitly* — rather than letting them fall through
the toolchain test into the package branch by accident — but still rendered them
in the Packages table, recording the recognition as a `PackageInfo.skill_bundle`
flag that changed no output. It said why: *"If a future decision wants skill
bundles rendered distinctly, the flag is already the hook to branch on."*

Two things have changed since.

The first is that the recognition is no longer a guess. Under
[ADR 0004](0004-registry-publishes-its-own-classification.md) the registry
stamps `kind = "skill-bundle"` itself and the docs generator reads it from
`nix eval .#manifest`. Rendering a category distinctly is only worth doing when
the boundary is trustworthy; it now is.

The second is that a skill bundle reads as a package only until you try to use
one. It installs no executables — it is a Claude Code plugin directory, consumed
through `programs.claude-code.plugins` or `.skills` rather than by putting
something on `PATH`. A reader scanning the Packages table for a tool has no way
to tell that `mattpocock-skills` is not one, and the two bundles currently in the
registry sit in that table between binaries.

## Decision

Route `kind = "skill-bundle"` entries into their own list in `build_models`, and
render them under a **Skill Bundles** heading with a fourth stat tile.

- **They keep `PackageInfo`.** A bundle has the same shape as a package — name,
  default, versions, releases, inactive — and renders through the same
  `_render_package_rows`. The list an entry lands in is now what marks it, so
  the `skill_bundle` flag is removed: it existed to carry a distinction the
  output did not make, and the output now makes it.
- **Their versions still count in the versions total.** The headline counts what
  the registry publishes, and a bundle version is as buildable as any other. The
  *Packages* tile counts packages only, so the two tiles answer different
  questions, as they already did for toolchains.
- **The section renders unconditionally**, like the other two. An empty Skill
  Bundles table is possible in principle but not in this registry, and a
  conditional section would be untested machinery guarding a case that does not
  arise.

## Consequences

- `build_models` returns three lists and `render_html` takes a third argument.
  This is the second category to get a section; a third would be the point to
  replace the growing tuple with a container rather than widen it again.
- The template gains `$num_skill_bundles` and `$skill_bundle_rows`.
  `Template.substitute` raises on a missing key, so the template and the
  renderer must change together — the failure is loud, not silent.
- `.stats` gains `flex-wrap: wrap` so a fourth tile does not overflow a narrow
  viewport.
