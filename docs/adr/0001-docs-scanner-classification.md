# 1. Docs scanner package classification: toolchains by name, skill bundles folded in

Date: 2026-07-17

## Status

Accepted

## Context

The docs generator (`docs/src/toolbox_docs/scanner.py`) walks `packages/*/data.json`
and classifies each entry into one of the categories the generated site renders:
plain **packages** and **toolchains**. Classification was extracted into the pure
`classify_entry(name, data)` seam (tb-dkx.1); this ADR records the two
classification *rules* it applies, both of which had drifted from how the Nix
registry decides the same things.

Two discrepancies motivated this decision (tb-dkx.2):

1. **Skill bundles.** A skill bundle (e.g. `mattpocock-skills`, whose `data.json`
   sets `_meta.fromClaudePlugin: true` and is built by `buildSkillBundle`) has a
   name that does not end in `-toolchain`, so it fell through to the package
   branch and was rendered as a plain package — silently, with nothing in the
   scanner acknowledging the category exists.

2. **Toolchain rule.** Python decides "toolchain" by `name.endswith("-toolchain")`.
   Nix decides by which builder is used (`buildToolchain`). These are different
   notions that happen to agree today. `classify_entry` is a **pure** function of
   `(name, data.json)` — it cannot observe which Nix builder a package uses, so it
   cannot mechanically adopt Nix's builder-based rule.

Relevant observation: `solana-toolchain/` is named `-toolchain` and is *not* built
with `buildToolchain` (it is a hand-written `symlinkJoin`), but it ships **no
`data.json`**, so the scanner skips it entirely. Every `-toolchain` directory the
scanner actually sees does use `buildToolchain` — so the name rule and the Nix
builder rule agree for the full set of entries the docs generator observes.

## Decision

**Toolchain rule — keep the name suffix, treat it as the contract.** A directory
whose name ends in `-toolchain` is classified as a toolchain. We do not attempt to
reconstruct Nix's builder-based notion inside the pure scanner. The naming
convention *is* the agreement: a package built with `buildToolchain` is named
`*-toolchain`, and a `*-toolchain` directory with a `data.json` is built with
`buildToolchain`. The one apparent divergence (`solana-toolchain`) is invisible to
the docs because it has no `data.json`, so no reconciliation is required for
correctness — only this documentation of why the simple rule is sufficient.

**Skill bundles — recognize explicitly, fold into the package list.** A `data.json`
is a skill bundle when its `_meta` carries the `fromClaudePlugin` key (the same
field `buildSkillBundle` reads; presence is the marker, regardless of its boolean
value). `classify_entry` recognizes this via `is_skill_bundle(data)` and records it
on `PackageInfo.skill_bundle`, but still returns a `PackageInfo` so the bundle
renders in the existing Packages section. Skill bundles do **not** get their own
docs section.

## Consequences

- Classification lives in one pure place and is covered by dict-fixture tests,
  including the skill-bundle branch — the recognition is explicit and tested, no
  longer an accidental fall-through.
- Generated HTML is unchanged: the renderer reads only the existing `PackageInfo`
  fields, so the new `skill_bundle` flag carries information without altering
  output. If a future decision wants skill bundles rendered distinctly, the flag
  is already the hook to branch on.
- The toolchain rule stays trivially cheap and legible. Its correctness depends on
  the naming convention (`buildToolchain` ⇒ `*-toolchain` name, with a committed
  `data.json`). If a toolchain is ever added without the suffix, or a
  `*-toolchain` directory gains a `data.json` without using `buildToolchain`, this
  rule would misclassify it and the ADR should be revisited.
