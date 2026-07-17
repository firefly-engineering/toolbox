{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "jjui";
    platforms = {
      "x86_64-linux" = "linux-amd64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-amd64";
      "aarch64-darwin" = "darwin-arm64";
    };
    url = { version, platform }:
      "https://github.com/idursun/jjui/releases/download/v${version}/jjui-${version}-${platform}.zip";
    binaries = [ { from = { version, platform }: "jjui-${version}-${platform}"; to = "jjui"; } ];
    sourceRoot = ".";
    meta = with lib; {
      description = "A TUI for Jujutsu version control";
      homepage = "https://github.com/idursun/jjui";
      license = licenses.mit;
      mainProgram = "jjui";
    };
  };
in
toolboxLib.buildPackage { name = "jjui"; dataPath = ./data.json; inherit builders; }
