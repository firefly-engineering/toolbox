{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "bun";
    platforms = {
      "x86_64-linux" = "linux-x64";
      "aarch64-linux" = "linux-aarch64";
      "x86_64-darwin" = "darwin-x64";
      "aarch64-darwin" = "darwin-aarch64";
    };
    url = { version, platform }:
      "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-${platform}.zip";
    binaries = [ "bun" ];
    sourceRoot = { version, platform }: "bun-${platform}";
    symlinks = { bunx = "bun"; };
    meta = with lib; {
      description = "Incredibly fast JavaScript runtime, bundler, test runner, and package manager";
      homepage = "https://bun.sh";
      license = lib.licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
toolboxLib.buildPackage { name = "bun"; dataPath = ./data.json; inherit builders; }
