{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "rust-analyzer";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-linux" = "aarch64-unknown-linux-gnu";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/rust-lang/rust-analyzer/releases/download/${version}/rust-analyzer-${platform}.gz";
    binaries = [ "rust-analyzer" ];
    meta = with lib; {
      description = "Rust language server for IDE support";
      homepage = "https://rust-analyzer.github.io/";
      license = with lib.licenses; [ asl20 mit ];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
toolboxLib.buildPackage { name = "rust-analyzer"; dataPath = ./data.json; inherit builders; }
