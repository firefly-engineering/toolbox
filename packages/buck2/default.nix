{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  # Map Nix system names to buck2 release triples
  targetTriple = {
    "x86_64-linux"   = "x86_64-unknown-linux-gnu";
    "aarch64-linux"  = "aarch64-unknown-linux-gnu";
    "x86_64-darwin"  = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "buck2 ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "buck2";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/facebook/buck2/releases/download/${version}/buck2-${targetTriple}.zst";
          hash = platformData.sha256;
        };

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = [
          pkgs.zstd
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          zstd -d $src -o $out/bin/buck2
          chmod +x $out/bin/buck2

          runHook postInstall
        '';

        meta = {
          description = "Buck2: fast, hermetic build system from Meta";
          homepage = "https://buck2.build/";
          license = with lib.licenses; [ asl20 mit ];
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
  versions = toolboxLib.buildVersions "buck2" builders versions;
  default = meta.default;
}
