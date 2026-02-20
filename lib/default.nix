{ lib }:

{
  # Read and parse a data.json file, separating _meta from version entries
  readData = path:
    let
      data = builtins.fromJSON (builtins.readFile path);
    in
    {
      meta = data._meta;
      versions = lib.filterAttrs (n: _: n != "_meta") data;
    };

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

  # Normalize a version string for use as a Nix attribute name
  # "1.25.6" -> "1_25_6"
  versionToAttr = builtins.replaceStrings [ "." ] [ "_" ];
}
