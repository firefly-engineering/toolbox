# Eval-time invariant check for the whole registry.
#
# The registry's interface is that every entry is `{ versions; default; }` —
# an attrset of version string -> derivation, plus the version key that
# `.#<pkg>` resolves to. Nothing enforced that. The only gate was building the
# full closure on a single system, so three of the four systems the flake
# advertises got no verification at all, and a bad `data.json` edit surfaced
# either as a build failure minutes in or (on darwin) not at all.
#
# checkRegistry asserts the interface at *evaluation* time. Forcing each
# version's `drvPath` instantiates the derivation without building it, which is
# what catches the interesting class of mistake: a version entry missing the
# hash its builder dereferences, a `builder` naming no builder, a toolchain
# component or cross-package pin that resolves to nothing. Those are all
# `attribute missing` / `throw` at instantiation.
#
# The check derivation itself is built for the *host* system, while the
# evaluation it forces spans every system the flake advertises. That split
# matters: instantiating a derivation is platform-independent, but realising
# one is not, so a per-system check derivation can only be built on a machine
# of that system — `nix flake check --all-systems` on a Linux runner fails
# trying to build the darwin check with "platform mismatch". Forcing all
# systems from one native derivation gets the coverage without the mismatch.
{ lib, availableVersions }:

{
  # checkRegistry { pkgs, systemRegistries, packagesDir } -> derivation
  #
  #   pkgs              nixpkgs for the *host* system; only builds the trivial
  #                     result derivation, so the check runs on any machine
  #   systemRegistries  [ { system; registry; hostPlatform; } ] — every system
  #                     the flake advertises. All of them are forced.
  #   packagesDir       path to packages/, for the on-disk invariants
  #
  # Throws with every violation listed at once — a report, not a first-failure.
  checkRegistry =
    { pkgs
    , systemRegistries
    , packagesDir
    }:
    let
      # Shape and stamp are properties of the data, identical on every system,
      # so they are checked once against the first registry. Availability is
      # what differs, and that is what the per-system forcing below covers.
      registry = (lib.head systemRegistries).registry;

      packageDirs = lib.attrNames (
        lib.filterAttrs (_: t: t == "directory") (builtins.readDir packagesDir)
      );

      # ── on-disk invariants ────────────────────────────────────────────────
      # Vendored patches are referenced by a relative path in data.json that
      # Nix only resolves when that version is built. Check every one now.
      patchProblems = lib.concatMap (
        name:
        let
          dataPath = packagesDir + "/${name}/data.json";
        in
        lib.optionals (builtins.pathExists dataPath) (
          let
            data = builtins.fromJSON (builtins.readFile dataPath);
            versions = lib.filterAttrs (k: v: k != "_meta" && builtins.isAttrs v) data;
          in
          lib.concatLists (
            lib.mapAttrsToList (
              version: versionData:
              map (p: "${name} ${version}: patch file '${p.file}' does not exist") (
                lib.filter (p: !builtins.pathExists (packagesDir + "/${name}/${p.file}")) (
                  versionData.patches or [ ]
                )
              )
            ) versions
          )
        )
      ) packageDirs;

      # ── interface invariants ──────────────────────────────────────────────
      kinds = [ "package" "toolchain" "skill-bundle" ];

      # The stamp is required, not optional-with-a-default. An entry that can
      # quietly go unstamped reintroduces the silent fall-through that made a
      # skill bundle render as a plain package (docs/adr/0001): the failure
      # mode of a missing classification is to look like the common case.
      stampProblems = lib.concatLists (
        lib.mapAttrsToList (
          name: entry:
          if !(entry ? toolbox) then
            [ "${name}: registry entry carries no `toolbox` stamp" ]
          else if !(entry.toolbox ? kind) then
            [ "${name}: `toolbox` stamp has no `kind`" ]
          else if !(lib.elem entry.toolbox.kind kinds) then
            [
              "${name}: unknown kind '${entry.toolbox.kind}' (expected one of ${
                lib.concatStringsSep ", " kinds
              })"
            ]
          else if entry.toolbox.kind == "toolchain" && entry.toolbox.components == null then
            [ "${name}: toolchain stamp carries no component pins" ]
          else
            [ ]
        ) registry
      );

      shapeProblems = lib.concatLists (
        lib.mapAttrsToList (
          name: entry:
          if !(entry ? versions) || !(entry ? default) then
            [ "${name}: registry entry is not { versions; default; }" ]
          else if entry.versions == { } then
            # A package may legitimately expose no versions on this system.
            [ ]
          else if !(entry.versions ? ${entry.default}) then
            [
              "${name}: _meta.default '${entry.default}' is not among its versions (${
                lib.concatStringsSep ", " (lib.attrNames entry.versions)
              })"
            ]
          else
            [ ]
        ) registry
      );

      problems = patchProblems ++ shapeProblems ++ stampProblems;

      # Instantiating every version forces the whole data.json -> derivation
      # path: missing hashes, unknown builders and dangling cross-package pins
      # all fail here. The context is discarded so the check derivation does
      # not gain a build dependency on all 380-odd packages — we want the
      # evaluation, not the closure.
      #
      # Derivations nixpkgs reports as unavailable here are skipped rather than
      # forced: `meta.platforms` is a legitimate way for a package to say it
      # does not exist on this system (packages/qmd is one), and forcing such a
      # derivation throws "refusing to evaluate" instead of telling us anything
      # about the registry.
      drvPaths = lib.concatMap (
        sr:
        lib.concatLists (
          lib.mapAttrsToList (
            _: entry:
            lib.mapAttrsToList (_: drv: builtins.unsafeDiscardStringContext drv.drvPath) (
              availableVersions sr.hostPlatform entry
            )
          ) sr.registry
        )
      ) systemRegistries;

      summary = ''
        systems:    ${lib.concatMapStringsSep ", " (sr: sr.system) systemRegistries}
        packages:   ${toString (lib.length (lib.attrNames registry))}
        versions:   ${toString (lib.length drvPaths)}
      '';
    in
    if problems != [ ] then
      throw ''
        toolbox registry check failed (${toString (lib.length problems)} problems):
        ${lib.concatMapStringsSep "\n" (p: "  - ${p}") problems}''
    else
      pkgs.runCommand "toolbox-registry-check"
        {
          # Referencing the instantiated paths here is what makes the check
          # depend on the evaluation having succeeded.
          inherit drvPaths;
          passAsFile = [ "drvPaths" ];
        }
        ''
          mkdir -p "$out"
          cp "$drvPathsPath" "$out/instantiated"
          cat > "$out/summary" <<'EOF'
          ${summary}
          EOF
        '';
}
