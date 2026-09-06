# Support code for Rust packages built from a tagged GitHub source with a
# toolbox-pinned Rust.
#
# buildRustPackage returns a *builder function* (version: versionData:
# derivation) that slots into buildPackage's `builders` attrset — the same
# shape buildPrebuiltBinary uses, and for the same reason: a package assembled
# this way can still grow additional builder variants.
#
# It hides the ritual every Rust package in this registry repeated verbatim:
# resolving the pinned Rust out of the registry, building a rustPlatform from
# it, fetching the tagged source, and wiring `versionData`'s hashes in.
#
#   let
#     builders.default = toolboxLib.buildRustPackage {
#       inherit pkgs toolbox;
#       pname = "cargo-edit";
#       owner = "killercup";
#       repo  = "cargo-edit";
#       extraArgs = {
#         nativeBuildInputs = [ pkgs.pkg-config ];
#         buildInputs = [ pkgs.openssl ];
#       };
#       meta = { ... };
#     };
#   in toolboxLib.buildPackage { name = "cargo-edit"; dataPath = ./data.json; inherit builders; }
#
# Dependency pinning follows the data, not a parameter: `cargoHash` is set from
# `versionData.cargoHash` when present. A package whose lockfile is vendored
# instead (its data.json carries no cargoHash) supplies `cargoLock` through
# `extraArgs`.
{ lib }:

{
  # buildRustPackage { pkgs; toolbox; pname; owner; repo; ... }
  #   -> version: versionData: derivation
  #
  # Required:
  #   pkgs       nixpkgs instance
  #   toolbox    the registry, for the pinned Rust (versionData.rust)
  #   pname      package name
  #   owner      GitHub owner
  #   repo       GitHub repo
  # Optional:
  #   rev        fn { version } -> git rev (default: "v${version}")
  #   extraArgs  extra buildRustPackage arguments — an attrset, or a fn
  #              { version, versionData, rust } -> attrset for the cases that
  #              need to interpolate the version (a version-namespaced
  #              Cargo.lock, env.CFG_RELEASE, …). Merged last, so it can
  #              override anything set here.
  #   meta       derivation meta
  buildRustPackage =
    { pkgs
    , toolbox
    , pname
    , owner
    , repo
    , rev ? ({ version }: "v${version}")
    , extraArgs ? { }
    , meta ? { }
    }:
    version: versionData:
    let
      rust = toolbox.rust.versions.${versionData.rust};
      rustPlatform = pkgs.makeRustPlatform {
        rustc = rust;
        cargo = rust;
      };

      resolvedExtra =
        if lib.isFunction extraArgs then extraArgs { inherit version versionData rust; } else extraArgs;
    in
    rustPlatform.buildRustPackage (
      {
        inherit pname version meta;

        src = pkgs.fetchFromGitHub {
          inherit owner repo;
          rev = rev { inherit version; };
          hash = versionData.sha256;
        };

        doCheck = false;
      }
      # Packages pinning deps by hash get cargoHash from the data; those
      # vendoring a lockfile carry no cargoHash and pass cargoLock via
      # extraArgs instead.
      // lib.optionalAttrs (versionData ? cargoHash) { cargoHash = versionData.cargoHash; }
      // resolvedExtra
    );
}
