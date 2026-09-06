{ lib }:

let
  # Read and parse a data.json file, separating _meta from version entries
  readData = path:
    let
      data = builtins.fromJSON (builtins.readFile path);
    in
    {
      meta = data._meta;
      versions = lib.filterAttrs (n: _: n != "_meta") data;
    };

  # Build all versions from a data.json versions attrset using named builders.
  # Each version entry may specify "builder" (defaults to "default").
  buildVersions = name: builders: versionEntries:
    builtins.mapAttrs (version: versionData:
      let
        builderName = versionData.builder or "default";
        builder = builders.${builderName}
          or (throw "Unknown builder '${builderName}' for ${name} ${version}");
      in
      builder version versionData
    ) versionEntries;

  # Build a registry package from a data.json file and a builders attrset.
  # The canonical entry point for versioned packages: reads meta+versions from
  # data.json, dispatches each version through `builders` (keyed by the optional
  # "builder" field, default "default"), and returns the { versions; default; }
  # shape the registry expects — the same shape buildToolchain/buildSkillBundle
  # produce. Reach for buildVersions directly only when a package needs to
  # pre-process its version set (e.g. platform filtering); see packages/bun-baseline.
  buildPackage = { name, dataPath, builders }:
    let
      inherit (readData dataPath) meta versions;
    in
    {
      versions = buildVersions name builders versions;
      default = meta.default;
    };
in
{
  inherit readData buildVersions buildPackage;

  # Resolve a tool from the registry by name and optional version
  # If version is null, returns the default version's derivation
  # If version is specified, returns that version's derivation
  resolveTool = registry: name: version:
    let
      entry = registry.${name}
        or (throw "Unknown tool '${name}' in toolbox registry");
      ver = if version == null then entry.default else version;
    in
    entry.versions.${ver}
      or (throw "Unknown version '${ver}' for tool '${name}'");

  # Build a toolchain meta-package from a data.json file.
  # Component names in data.json must match toolbox package names.
  buildToolchain = { toolbox, pkgs, name, dataPath }:
    let
      inherit (readData dataPath) meta versions;
      mkToolchain = version: versionData:
        let
          components = lib.mapAttrsToList (component: ver:
            toolbox.${component}.versions.${ver}
          ) versionData;

          # A toolchain exists only where *every* component exists. Without
          # this the symlinkJoin advertises no platforms at all, i.e. "runs
          # everywhere", while forcing it throws because a component declined
          # the system — llm-toolchain bundling qmd (x86_64-linux and
          # aarch64-darwin only) was silently unbuildable on aarch64-linux.
          # A component that states no platforms imposes no constraint.
          platforms = lib.foldl' (acc: drv:
            let p = drv.meta.platforms or null; in
            if p == null then acc
            else if acc == null then p
            else lib.intersectLists acc p
          ) null components;
        in
        pkgs.symlinkJoin {
          name = "${name}-${version}";
          paths = components;
          meta = lib.optionalAttrs (platforms != null) { inherit platforms; };
        };
    in
    {
      versions = builtins.mapAttrs mkToolchain versions;
      default = meta.default;
    };

  # Resolve local patch files from version data.
  # Returns a list of paths suitable for mkDerivation's `patches` attribute.
  # packageDir: the package's directory (e.g. ./.)
  # versionData: the version entry from data.json
  resolvePatches = packageDir: versionData:
    map (p: packageDir + "/${p.file}") (versionData.patches or []);

  # Normalize a version string for use as a Nix attribute name
  # "1.25.6" -> "1_25_6"
  versionToAttr = builtins.replaceStrings [ "." ] [ "_" ];
}
# Skill-bundle support code lives in its own file for separation from the small
# registry helpers above; merged in so it's reachable as toolboxLib.buildSkillBundle.
// import ./skill-bundle.nix { inherit lib readData; }
# Prebuilt-binary builder, likewise in its own file; reachable as
# toolboxLib.buildPrebuiltBinary.
// import ./prebuilt-binary.nix { inherit lib; }
# Registry-wide invariant check, reachable as toolboxLib.checkRegistry.
// import ./check-registry.nix { inherit lib; }
