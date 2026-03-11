{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  targetTriple = {
    "x86_64-linux"   = "x86_64-unknown-linux-gnu";
    "aarch64-linux"  = "aarch64-unknown-linux-musl";
    "x86_64-darwin"  = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "mdbook ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "mdbook";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/rust-lang/mdBook/releases/download/v${version}/mdbook-v${version}-${targetTriple}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = ".";

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -m755 mdbook $out/bin/mdbook

          runHook postInstall
        '';

        meta = {
          description = "Create books from Markdown files";
          homepage = "https://rust-lang.github.io/mdBook/";
          license = lib.licenses.mpl20;
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
  versions = toolboxLib.buildVersions "mdbook" builders versions;
  default = meta.default;
}
