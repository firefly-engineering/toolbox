{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  system = pkgs.stdenv.hostPlatform.system;

  supportedPlatforms = {
    "x86_64-linux"  = "linux-x64-baseline";
    "x86_64-darwin" = "darwin-x64-baseline";
  };

  platformKey = supportedPlatforms.${system} or null;

  # Only include versions that have binaries for the current platform
  filteredVersions = lib.filterAttrs (_: versionData: versionData ? ${system}) versions;

  builders = {
    default = version: versionData:
      let
        platformData = versionData.${system};
      in
      pkgs.stdenv.mkDerivation {
        pname = "bun-baseline";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-${platformKey}.zip";
          hash = platformData.sha256;
        };

        sourceRoot = "bun-${platformKey}";

        nativeBuildInputs = [
          pkgs.unzip
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -m 755 bun $out/bin/bun
          ln -s $out/bin/bun $out/bin/bunx

          runHook postInstall
        '';

        meta = {
          description = "Bun JavaScript runtime (baseline build, no AVX2 requirement)";
          homepage = "https://bun.sh";
          license = lib.licenses.mit;
          platforms = builtins.attrNames supportedPlatforms;
        };
      };
  };
in
# On unsupported platforms, expose no versions so the flake skips this package gracefully
if filteredVersions == {} then {
  versions = {};
  default = meta.default;
} else {
  versions = toolboxLib.buildVersions "bun-baseline" builders filteredVersions;
  default = meta.default;
}
