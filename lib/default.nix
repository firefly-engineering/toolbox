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

  # The versions of a registry entry that exist on a given platform.
  #
  # `meta.platforms` is one of the ways a package says "not here" — packages/qmd
  # names the two systems its node_modules hashes cover, and buildToolchain
  # intersects its components' lists. Anything that *enumerates* versions must
  # respect it: nixpkgs throws "refusing to evaluate" when an unavailable
  # derivation is forced, so an unfiltered enumeration produces flake outputs
  # that exist right up until someone touches them.
  availableVersions = hostPlatform: entry:
    lib.filterAttrs (_: drv: lib.meta.availableOn hostPlatform drv) entry.versions;

  # Normalize a version string for use as a Nix attribute name
  # "1.25.6" -> "1_25_6"
  versionToAttr = builtins.replaceStrings [ "." ] [ "_" ];

  # The flake's two package outputs, derived from the registry.
  #
  # This mapping — which versions appear, how a version string becomes an
  # attribute name, and that the bare package name means the default version —
  # is the registry's public naming contract, so it lives with the registry
  # rather than being spelled twice in flake.nix (which had its own copy of
  # versionToAttr and never used the one lib exports).
  #
  #   nested  name -> { "1_25_6" = drv; default = drv; }   (legacyPackages)
  #   flat    "go-1_25_6" = drv; "go" = drv;               (packages)
  registryOutputs = { pkgs, registry }:
    let
      hostPlatform = pkgs.stdenv.hostPlatform;

      # A package with no version available here contributes nothing, and one
      # whose default is unavailable contributes its other versions but no
      # bare/default attribute.
      entryAttrs = name: entry:
        let
          avail = availableVersions hostPlatform entry;
          hasDefault = avail ? ${entry.default};
        in
        { inherit avail hasDefault; };
    in
    {
      nested = builtins.mapAttrs (
        name: entry:
        let inherit (entryAttrs name entry) avail hasDefault; in
        lib.mapAttrs' (ver: drv: lib.nameValuePair (versionToAttr ver) drv) avail
        // lib.optionalAttrs hasDefault { default = avail.${entry.default}; }
      ) registry;

      flat = lib.concatMapAttrs (
        name: entry:
        let inherit (entryAttrs name entry) avail hasDefault; in
        lib.mapAttrs' (ver: drv: lib.nameValuePair "${name}-${versionToAttr ver}" drv) avail
        // lib.optionalAttrs hasDefault {
          # Bare package name points to the default version
          ${name} = avail.${entry.default};
          # Deprecated: use bare package name instead (e.g., .#go not .#go-default)
          "${name}-default" = builtins.trace
            "warning: toolbox: '${name}-default' is deprecated, use '${name}' instead"
            avail.${entry.default};
        }
      ) registry;
    };

  # Every registry entry carries a `toolbox` stamp alongside its versions: the
  # facts about a package that only its *builder* knows, published so consumers
  # do not have to re-derive them from the directory name or the shape of
  # data.json.
  #
  # This exists because the docs generator kept having to guess. It classified
  # "toolchain" by a `-toolchain` name suffix and "skill bundle" by the presence
  # of a `_meta.fromClaudePlugin` key, because a pure function of
  # (name, data.json) cannot observe which builder assembled a package — see
  # docs/adr/0001 and 0004. `kind` is that observation, stated by the builder
  # that actually made the choice.
  #
  #   kind        "package" | "toolchain" | "skill-bundle"
  #   releases    upstream releases URL from _meta, or null
  #   inactive    _meta.inactive, default false
  #   components  toolchains only: { <version> = { <component> = <pin>; }; }
  mkStamp = { kind, meta, components ? null }: {
    inherit kind components;
    releases = meta.releases or null;
    inactive = meta.inactive or false;
  };

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
      toolbox = mkStamp { kind = "package"; inherit meta; };
    };
in
{
  inherit readData buildVersions buildPackage availableVersions versionToAttr registryOutputs mkStamp;

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
      # A toolchain's version entry *is* its component pin map, so the stamp
      # carries it: the docs render the expansion, and reading it back out of
      # data.json is exactly the re-derivation the stamp exists to remove.
      toolbox = mkStamp {
        kind = "toolchain";
        inherit meta;
        components = versions;
      };
    };

  # Resolve local patch files from version data.
  # Returns a list of paths suitable for mkDerivation's `patches` attribute.
  # packageDir: the package's directory (e.g. ./.)
  # versionData: the version entry from data.json
  resolvePatches = packageDir: versionData:
    map (p: packageDir + "/${p.file}") (versionData.patches or []);

}
# Skill-bundle support code lives in its own file for separation from the small
# registry helpers above; merged in so it's reachable as toolboxLib.buildSkillBundle.
// import ./skill-bundle.nix { inherit lib readData mkStamp; }
# Prebuilt-binary builder, likewise in its own file; reachable as
# toolboxLib.buildPrebuiltBinary.
// import ./prebuilt-binary.nix { inherit lib; }
# Rust source builder, reachable as toolboxLib.buildRustPackage.
// import ./rust-package.nix { inherit lib; }
# Go source builder, reachable as toolboxLib.buildGoPackage.
// import ./go-package.nix { inherit lib; }
# Registry manifest for non-Nix consumers, reachable as toolboxLib.registryManifest.
// import ./manifest.nix { inherit lib; }
# Registry-wide invariant check, reachable as toolboxLib.checkRegistry.
// import ./check-registry.nix { inherit lib availableVersions; }
