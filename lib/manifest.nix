# The registry, serialised for consumers that are not Nix.
#
# The docs generator used to walk `packages/*/data.json` and reconstruct what
# the registry knew: "toolchain" from a name suffix, "skill bundle" from a
# `_meta` key, a package's very existence from having a data file at all. Every
# one of those was a guess standing in for a fact the builder had already
# decided (docs/adr/0001, 0002, 0003 — all three the same shape). The manifest
# publishes the facts instead.
#
# It spans systems rather than picking one. Platform availability is decided by
# `meta.platforms`, which is Nix-side knowledge, so a single-system manifest
# would be silently wrong for every package that does not exist everywhere.
# Recording it per version is the ground truth: availability happens to be
# uniform across a package's versions today, but `delta` has already been the
# counter-example once.
#
# Version order is deliberately unspecified. Ordering is presentation, and the
# consumer that renders it owns the natural-sort semantics.
{ lib }:

{
  # registryManifest { systemRegistries } -> attrset (JSON-ready)
  #
  #   systemRegistries  [ { system; registry; hostPlatform; } ]
  #
  # Shape:
  #   { packages = { <name> = {
  #       kind; default; releases; inactive; components;
  #       versions = { <version> = { systems = [ <system> ]; }; };
  #     }; }; }
  registryManifest =
    { systemRegistries }:
    let
      # Every system sees the same package set and the same version keys — both
      # come from data.json. Availability is what differs, so the key set is
      # taken from the first and availability is asked of each.
      base = (lib.head systemRegistries).registry;

      systemsFor =
        name: version:
        map (sr: sr.system) (
          lib.filter (
            sr:
            let
              entry = sr.registry.${name} or null;
            in
            entry != null
            && (lib.filterAttrs (_: drv: lib.meta.availableOn sr.hostPlatform drv) entry.versions) ? ${version}
          ) systemRegistries
        );

      entryManifest =
        name: entry:
        {
          inherit (entry.toolbox) kind releases inactive components;
          inherit (entry) default;
          versions = lib.mapAttrs (version: _: {
            systems = systemsFor name version;
          }) entry.versions;
        };
    in
    {
      packages = lib.mapAttrs entryManifest base;
    };
}
