# 4. The registry publishes its own classification; the docs generator reads it

Date: 2026-09-06

## Status

Accepted

Supersedes [ADR 0001](0001-docs-scanner-classification.md) and
[ADR 0002](0002-docs-scanner-shared-version-data.md). Narrows
[ADR 0003](0003-solana-toolchain-data-json.md).

## Context

Three ADRs in a row solved the same problem. Each was locally sound; together
they trace a seam in the wrong place.

- **0001** — the docs generator classified a package by its *directory name*
  (`name.endswith("-toolchain")`) and recognised a skill bundle by the presence
  of a `_meta.fromClaudePlugin` key. It said why: *"`classify_entry` is a pure
  function of `(name, data.json)` — it cannot observe which Nix builder a
  package uses."*
- **0002** — `tuicr-skills` builds from its sibling's data file, so it had no
  `data.json` of its own and vanished from the docs. The fix invented
  `_meta.dataFrom`, a pointer file **read only by the docs generator**. Nix
  ignored it: `packages/tuicr-skills/default.nix` names `../tuicr/data.json`
  directly. Two mechanisms expressed one fact and were free to disagree
  silently.
- **0003** — `solana-toolchain` vanished for a weaker reason (no data file at
  all), and gained one partly so the docs would find it.

The common cause: the docs generator discovered and classified packages by
walking `packages/*/data.json`, reconstructing from filenames and JSON
conventions what the Nix builders had already decided. `data.json` answers to
neither consumer — Nix reads it and *makes* decisions; Python read it and
*guessed at* those same decisions from outside.

A fourth symptom made the cost concrete. Once `buildToolchain` began
propagating its components' `meta.platforms` and the flake outputs began
respecting availability, the site and the flake measurably diverged:
`bun-baseline` is `x86_64-linux` only, and `llm-toolchain` and `qmd` are absent
on `aarch64-linux`, while the docs listed every version unconditionally. The
scanner *cannot* fix this — availability is decided by `meta.platforms` in
`default.nix`, Nix-side knowledge by construction.

## Decision

**Every registry entry carries a `toolbox` stamp.** Alongside `versions` and
`default`, each entry publishes `{ kind; releases; inactive; components; }`.
`kind` is one of `package`, `toolchain`, `skill-bundle`, stated by the builder
that made the choice. `buildPackage`, `buildToolchain` and `buildSkillBundle`
stamp their own; `solana-toolchain`, which hand-builds its return, stamps
manually. `checkRegistry` requires the stamp — optional-with-a-default would
reinstate the silent fall-through that made a skill bundle render as a plain
package, because a missing classification's natural failure mode is to look
like the common case.

**The flake exposes a `manifest` output.** `nix eval --json .#manifest`
serialises the registry: the stamp, plus each version and the systems it is
actually available on. It spans every advertised system, because a
single-system manifest would be silently wrong for the three packages above.
Availability is recorded per *version* — uniform across a package's versions
today, but `delta@0.19.2` has already been the counter-example.

This is not the rejected pattern of ADR 0002. That ADR ruled out reconstructing
facts by *scraping `default.nix` with regexes*, which is brittle and is a
rejected pattern in this repo generally. Asking the Nix evaluator is the
opposite: it is the authority answering directly.

**The docs generator reads the manifest.** `scan_packages`, `classify_entry`,
`is_skill_bundle`, `resolve_data_from` and `parse_toolchain_data` are deleted.
The generator receives the manifest path as an argument, so `__main__` remains
the sole I/O edge. Version *ordering* stays in Python: the manifest leaves order
unspecified because ordering is presentation, and `sorting.version_key` owns the
natural-sort semantics.

The manifest is **not committed**. 152 of the last 203 commits touch a
`packages/*/data.json`, so a committed artifact would regenerate on three
commits out of four and turn every version bump into a two-file change. The
docs CI job installs Nix and evaluates it; the test job stays pure Python on
fixture manifests.

## Consequences

- Classification lives in the one place that can observe it. Adding a package
  category is a builder change, not an ADR.
- `_meta.dataFrom` and `packages/tuicr-skills/data.json` are deleted. A package
  no longer needs a data file to be documented, which is precisely what ADR 0002
  worked around.
- ADR 0003's "every package directory ships a `data.json`" invariant, and the
  `checkRegistry` check enforcing it, are removed as obsolete — replaced by the
  stamp requirement, which is strictly stronger: an empty pointer file satisfied
  the old rule. **ADR 0003's own decision stands**; giving `solana-toolchain` a
  `data.json` remains right because it made the pin data-driven, which is this
  repo's convention independently of the docs.
- The docs CI job now depends on Nix. Evaluating the manifest costs about five
  seconds cold; the Nix install dominates.
- The generated site is **unchanged**. This moved the seam and nothing else,
  verified by diffing the rendered HTML. Availability is recorded in the
  manifest but not yet rendered, which is the obvious next step and now a pure
  renderer change.
- Skill bundles still fold into the package list. ADR 0001 decided that, and it
  survives as what it always was — a *rendering* decision, now cleanly separated
  from classification. `kind` makes giving them their own section a one-line
  change if that is ever wanted.
- `meta.description`, `homepage` and `license` are deliberately **not** in the
  manifest yet. They are not rendered today, and `license` is inconsistently
  typed across packages (a set for `jq`, a list for `uv`); normalising it belongs
  with the change that renders it.
