# 3. `solana-toolchain` gains a `data.json`; the name-suffix toolchain rule holds

Date: 2026-08-06

## Status

Accepted

Revisits the toolchain-rule consequence of ADR 0001.

## Context

ADR 0001 kept the docs scanner's toolchain rule as `name.endswith("-toolchain")`
rather than reconstructing Nix's builder-based notion (`buildToolchain`), noting
that the two agree for every entry the scanner *observes*. Its one recorded
exception was `solana-toolchain/`: named `-toolchain`, built by hand as a
`symlinkJoin` (its wrapped `cargo-build-sbf` is custom logic `buildToolchain`
does not model), and invisible to the docs because it ships no `data.json`. ADR
0001 explicitly asked to revisit if a `*-toolchain` directory ever gained a
`data.json` without using `buildToolchain`.

That is now the case. `solana-toolchain` was one of only two packages missing
from the generated site (the other, `tuicr-skills`, is ADR 0002), and for a
weaker reason: it had no data file *anywhere*: its version and its
`platform-tools` pin were hardcoded in `default.nix`, against this repo's
data-driven convention that a version bump is a JSON edit, not a Nix edit.

## Decision

**Give `solana-toolchain` a `data.json`** in the ordinary toolchain shape — a
`_meta.default` plus one version entry mapping toolbox component names to pins —
and have `default.nix` read it with `toolboxLib.readData`. The package remains a
hand-written `symlinkJoin`; only the pin moves.

**Keep the name-suffix rule.** The scanner now sees a `*-toolchain` directory
that is not built with `buildToolchain`, and classifies it as a toolchain — which
is *correct*: it is a toolchain in the sense the docs render (a meta-package
bundling tools, expanded to its component pins). The divergence ADR 0001 worried
about is between the name rule and the *Nix builder*, and it does not produce a
misclassification here, because the builder was never what "toolchain" means to
a reader of the docs. The rule stands; ADR 0001's consequence is narrowed
accordingly: `buildToolchain` implies a `*-toolchain` name, but not the converse.

## Consequences

- `solana-toolchain` appears on the generated site, expanded to its one toolbox
  component (`platform-tools`).
- Its expansion lists only *toolbox* components. `solana-cli`, `anchor`, and
  `rustup` come from nixpkgs and have no pin to show, so the rendered expansion
  is narrower than what the toolchain actually bundles. Accepted: the same is
  true of the docs generally, which document this registry, not nixpkgs.
- Bumping the platform-tools pin is now a JSON edit, consistent with every other
  package.
- Every directory under `packages/` now has a `data.json`, so "no data file" is
  no longer a silent way for a package to vanish from the docs. The invariant is
  enforced mechanically rather than left to prose: a test asserts that every
  package directory the flake would discover is also discovered by the scanner.
