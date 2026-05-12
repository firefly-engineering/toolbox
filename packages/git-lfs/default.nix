{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  assetSpec = {
    "x86_64-linux"   = { suffix = "linux-amd64";  ext = "tar.gz"; };
    "aarch64-linux"  = { suffix = "linux-arm64";  ext = "tar.gz"; };
    "x86_64-darwin"  = { suffix = "darwin-amd64"; ext = "zip"; };
    "aarch64-darwin" = { suffix = "darwin-arm64"; ext = "zip"; };
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "git-lfs ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "git-lfs";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/git-lfs/git-lfs/releases/download/v${version}/git-lfs-${assetSpec.suffix}-v${version}.${assetSpec.ext}";
          hash = platformData.sha256;
        };

        sourceRoot = "git-lfs-${version}";

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = [ pkgs.installShellFiles ]
          ++ lib.optionals (assetSpec.ext == "zip") [ pkgs.unzip ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          runHook preInstall

          install -Dm755 git-lfs $out/bin/git-lfs
          installManPage man/man1/*.1 man/man5/*.5 man/man7/*.7

          runHook postInstall
        '';

        meta = with lib; {
          description = "Git extension for versioning large files";
          homepage = "https://git-lfs.com";
          license = licenses.mit;
          mainProgram = "git-lfs";
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
  versions = toolboxLib.buildVersions "git-lfs" builders versions;
  default = meta.default;
}
