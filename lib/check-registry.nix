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
# It is cheap enough to run on all four systems in CI.
{ lib }:

{
  # checkRegistry { pkgs, registry, packagesDir } -> derivation
  #
  #   pkgs         nixpkgs instance (for runCommand)
  #   registry     the assembled registry: name -> { versions; default; }
  #   packagesDir  path to packages/, for the on-disk invariants
  #
  # Throws with every violation listed at once — a report, not a first-failure.
  checkRegistry =
    { pkgs
    , registry
    , packagesDir
    }:
    let
      packageDirs = lib.attrNames (
        lib.filterAttrs (_: t: t == "directory") (builtins.readDir packagesDir)
      );

      # ── on-disk invariants ────────────────────────────────────────────────
      # Every package directory the flake discovers must ship a data.json.
      # ADR 0003 made this true and asserted it from the *docs* test suite;
      # it belongs here, on the side that owns the registry.
      missingData = map (name: "${name}: has default.nix but no data.json") (
        lib.filter (
          name:
          builtins.pathExists (packagesDir + "/${name}/default.nix")
          && !builtins.pathExists (packagesDir + "/${name}/data.json")
        ) packageDirs
      );

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

      problems = missingData ++ patchProblems ++ shapeProblems;

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
      drvPaths = lib.concatLists (
        lib.mapAttrsToList (
          _: entry:
          lib.mapAttrsToList (_: drv: builtins.unsafeDiscardStringContext drv.drvPath) (
            lib.filterAttrs (_: drv: lib.meta.availableOn pkgs.stdenv.hostPlatform drv) entry.versions
          )
        ) registry
      );

      summary = ''
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
