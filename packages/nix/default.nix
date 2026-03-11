{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      pkgs.llvmPackages.stdenv.mkDerivation {
        pname = "nix";
        inherit version;

        src = pkgs.fetchFromGitHub {
          owner = "NixOS";
          repo = "nix";
          rev = version;
          hash = versionData.sha256;
        };

        nativeBuildInputs = [
          pkgs.meson
          pkgs.ninja
          pkgs.pkg-config
          pkgs.bison
          pkgs.flex
          pkgs.cmake
          pkgs.jq
        ];

        buildInputs = [
          pkgs.boost
          pkgs.boehmgc
          pkgs.curl
          pkgs.libblake3
          pkgs.libsodium
          pkgs.openssl
          pkgs.sqlite
          pkgs.editline
          pkgs.libgit2
          pkgs.lowdown
          pkgs.bzip2
          pkgs.xz
          pkgs.nlohmann_json
          pkgs.libarchive
          pkgs.toml11
        ] ++ lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) [
          pkgs.libcpuid
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.libseccomp
        ];

        mesonAutoFeatures = "auto";

        mesonFlags = [
          "-Dlocalstatedir=/nix/var"
          "-Ddoc-gen=false"
          "-Dunit-tests=false"
          "-Dbindings=false"
          "-Djson-schema-checks=false"
        ];

        doCheck = false;

        meta = {
          description = "Nix package manager";
          homepage = "https://nixos.org/nix/";
          license = lib.licenses.lgpl21Plus;
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ];
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "nix" builders versions;
  default = meta.default;
}
