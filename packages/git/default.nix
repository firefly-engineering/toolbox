{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      pkgs.stdenv.mkDerivation {
        pname = "git";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
          hash = versionData.sha256;
        };

        nativeBuildInputs = [ pkgs.pkg-config pkgs.gettext ];

        buildInputs = [
          pkgs.curl
          pkgs.openssl
          pkgs.zlib
          pkgs.pcre2
          pkgs.expat
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          pkgs.apple-sdk_15
        ];

        makeFlags = [
          "prefix=$(out)"
          "NO_TCLTK=1"
          "INSTALL_SYMLINKS=1"
          # Rust libgitcore is optional through Git 2.x (mandatory in 3.0). Disable it
          # to avoid pulling a Rust toolchain + crate vendoring; no-op for pre-2.55 versions.
          "NO_RUST=1"
        ];

        doCheck = false;

        meta = with lib; {
          description = "Distributed version control system";
          homepage = "https://git-scm.com";
          license = licenses.gpl2Only;
          mainProgram = "git";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "git" builders versions;
  default = meta.default;
}
