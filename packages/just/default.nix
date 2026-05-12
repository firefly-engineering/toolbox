{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  targetTriple = {
    "x86_64-linux"   = "x86_64-unknown-linux-musl";
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
          or (throw "just ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "just";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/casey/just/releases/download/${version}/just-${version}-${targetTriple}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = ".";

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = [ pkgs.installShellFiles ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          runHook preInstall

          install -Dm755 just $out/bin/just
          installManPage just.1
          installShellCompletion completions/just.{bash,fish,zsh}

          runHook postInstall
        '';

        meta = with lib; {
          description = "A handy way to save and run project-specific commands";
          homepage = "https://github.com/casey/just";
          license = licenses.cc0;
          mainProgram = "just";
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
  versions = toolboxLib.buildVersions "just" builders versions;
  default = meta.default;
}
