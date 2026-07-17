{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "hunk";
    platforms = {
      "x86_64-linux" = "linux-x64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-x64";
      "aarch64-darwin" = "darwin-arm64";
    };
    url = { version, platform }:
      "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-${platform}.tar.gz";
    binaries = [ "hunk" ];
    sourceRoot = { version, platform }: "hunkdiff-${platform}";
    postInstall = ''
      ln -s hunk $out/bin/hunkdiff
      cp -r skills $out/skills
      install -m644 metadata.json $out/metadata.json
    '';
    meta = with lib; {
      description = "Review-first terminal diff viewer for agentic coders";
      homepage = "https://github.com/modem-dev/hunk";
      license = licenses.mit;
      mainProgram = "hunk";
      platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    };
  };
in
toolboxLib.buildPackage { name = "hunk"; dataPath = ./data.json; inherit builders; }
