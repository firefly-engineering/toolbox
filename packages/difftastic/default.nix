{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "difftastic";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-linux" = "aarch64-unknown-linux-gnu";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/Wilfred/difftastic/releases/download/${version}/difft-${platform}.tar.gz";
    binaries = [ "difft" ];
    sourceRoot = ".";
    meta = with lib; {
      description = "A structural diff tool that understands syntax";
      homepage = "https://difftastic.wilfred.me.uk";
      license = licenses.mit;
      mainProgram = "difft";
    };
  };
in
toolboxLib.buildPackage { name = "difftastic"; dataPath = ./data.json; inherit builders; }
