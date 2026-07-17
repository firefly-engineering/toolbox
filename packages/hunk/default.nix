{ pkgs, lib, toolbox, toolboxLib }:

let
  assetPlatform = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "hunk ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "hunk";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-${assetPlatform}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = "hunkdiff-${assetPlatform}";

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
          install -m755 hunk $out/bin/hunk
          ln -s hunk $out/bin/hunkdiff

          # Bundle the assets shipped alongside the binary. hunk resolves the
          # review skill by walking up from process.execPath ($out/bin/hunk)
          # looking for skills/hunk-review/SKILL.md, so the skills/ directory
          # must sit next to bin/ at $out. metadata.json is shipped likewise.
          cp -r skills $out/skills
          install -m644 metadata.json $out/metadata.json

          runHook postInstall
        '';

        meta = with lib; {
          description = "Review-first terminal diff viewer for agentic coders";
          homepage = "https://github.com/modem-dev/hunk";
          license = licenses.mit;
          mainProgram = "hunk";
          platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        };
      };
  };
in
toolboxLib.buildPackage { name = "hunk"; dataPath = ./data.json; inherit builders; }
