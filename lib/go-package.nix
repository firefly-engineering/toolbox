# Support code for Go packages built from a tagged GitHub source with a
# toolbox-pinned Go.
#
# buildGoPackage returns a *builder function* (version: versionData:
# derivation) that slots into buildPackage's `builders` attrset — the sibling
# of buildRustPackage, and the same shape as buildPrebuiltBinary.
#
#   let
#     builders.default = toolboxLib.buildGoPackage {
#       inherit pkgs toolbox;
#       pname = "gotestsum";
#       owner = "gotestyourself";
#       repo  = "gotestsum";
#       subPackages = [ "." ];
#       meta = { ... };
#     };
#   in toolboxLib.buildPackage { name = "gotestsum"; dataPath = ./data.json; inherit builders; }
#
# The Rust and Go clusters get separate helpers rather than one
# `buildFromSource`, because everything that identifies the language differs:
# the toolchain pin field (versionData.go vs .rust), how the platform is
# constructed (buildGoModule.override vs makeRustPlatform), and the dependency
# hash field (vendorHash vs cargoHash).
{ lib }:

{
  # buildGoPackage { pkgs; toolbox; pname; owner; repo; ... }
  #   -> version: versionData: derivation
  #
  # Required:
  #   pkgs         nixpkgs instance
  #   toolbox      the registry, for the pinned Go (versionData.go)
  #   pname        package name
  #   owner        GitHub owner
  #   repo         GitHub repo
  # Optional:
  #   rev          fn { version } -> git rev (default: "v${version}")
  #   subPackages  build targets; `versionData.subPackages` wins when the data
  #                supplies it (default: [ "." ])
  #   extraArgs    extra buildGoModule arguments — an attrset, or a fn
  #                { version, versionData, go } -> attrset for the cases that
  #                need the resolved Go or the version. Merged last.
  #   meta         derivation meta
  buildGoPackage =
    { pkgs
    , toolbox
    , pname
    , owner
    , repo
    , rev ? ({ version }: "v${version}")
    , subPackages ? [ "." ]
    , extraArgs ? { }
    , meta ? { }
    }:
    version: versionData:
    let
      go = toolbox.go.versions.${versionData.go};

      resolvedExtra =
        if lib.isFunction extraArgs then extraArgs { inherit version versionData go; } else extraArgs;
    in
    (pkgs.buildGoModule.override { inherit go; }) (
      {
        inherit pname version meta;

        src = pkgs.fetchFromGitHub {
          inherit owner repo;
          rev = rev { inherit version; };
          hash = versionData.sha256;
        };

        vendorHash = versionData.vendorHash;
        subPackages = versionData.subPackages or subPackages;
        doCheck = false;
      }
      // resolvedExtra
    );
}
