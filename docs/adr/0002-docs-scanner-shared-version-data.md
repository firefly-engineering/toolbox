# 2. Docs scanner: shared version data via `_meta.dataFrom`

Date: 2026-08-06

## Status

Accepted

## Context

`packages/tuicr-skills/` packages the agent skill that ships *inside the tuicr
source tree*. Its Nix builder deliberately points at the sibling's data file —
`buildSkillBundle { dataPath = ../tuicr/data.json; }` — so the skill and the
binary can never pin different revisions of tuicr. There is one place to bump.

The docs generator, however, discovers packages by walking `packages/*/` and
requiring a `data.json` **in the directory itself** (`scanner.py`). A package
with no data file of its own is skipped, so `tuicr-skills` was absent from the
generated site while being fully present in the flake, which discovers packages
by `builtins.readDir ./packages` and imports `default.nix`.

Two properties are in tension:

1. **One pin, one place.** Duplicating the `owner`/`repo`/`rev`/`sha256` into a
   second `data.json` restores docs discovery but reintroduces exactly the drift
   the shared `dataPath` was written to prevent.
2. **Data-driven discovery.** The scanner must not reconstruct the pin by
   reading `default.nix`; scraping Nix source with regexes is brittle and is a
   rejected pattern in this repo.

There is also a fact the shared file cannot carry: `tuicr/data.json` is the
*binary's* data, so it does not (and must not) set `_meta.fromClaudePlugin`.
Even if the scanner reached it, `tuicr-skills` would render as a plain package
rather than a skill bundle (see ADR 0001 for that marker).

## Decision

A package directory may ship a **pointer `data.json`** whose `_meta` carries
`dataFrom: "<sibling-package-name>"` and no version entries:

```json
{
  "_meta": {
    "dataFrom": "tuicr",
    "fromClaudePlugin": false,
    "releases": "https://github.com/agavra/tuicr/releases"
  }
}
```

`scan_packages` resolves the pointer by loading `packages/<sibling>/data.json`
and merging via the pure `resolve_data_from(local, source)`:

- **Version entries** come wholesale from the source. The pointer package never
  restates a hash.
- **`_meta`** is the source's, overridden field by field by the local one. This
  is where the pointer package states what is true of *itself* rather than of
  its source — the `fromClaudePlugin` marker, a different `releases` URL, and so
  on.
- **`dataFrom` is dropped** from the merged result, so `classify_entry` sees an
  ordinary `data.json` and needs no change.

A `dataFrom` naming a directory with no `data.json` is a hard error, not a
silent skip: a dangling pointer means the docs would quietly lose a package
again, which is the bug this ADR exists to fix.

The pointer file is **read only by the docs generator**. Nix continues to read
the shared file directly through `dataPath`; the pointer adds no second source
of truth because it contains no version data.

## Consequences

- `tuicr-skills` appears on the generated site, with the tuicr versions it is
  actually built from, correctly flagged as a skill bundle — and still with
  exactly one place to bump the pin.
- The filesystem lookup stays in `scan_packages`; the merge is a pure
  dict-in/dict-out function tested without an on-disk tree, matching the seam
  ADR 0001 established for `classify_entry`.
- A package directory now needs a `data.json` to be documented even when Nix
  does not read one from it. That is a mild redundancy, accepted because the
  alternative — inferring `dataPath` from `default.nix` — means parsing Nix.
- The convention generalizes: any future package sharing a source pin with a
  sibling (a second bundle, a companion tool built from one tree) gets docs
  discovery for a three-line file.
