{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "mdbook";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/rust-lang/mdBook/releases/download/v${version}/mdbook-v${version}-${platform}.tar.gz";
    binaries = [ "mdbook" ];
    sourceRoot = ".";
    meta = with lib; {
      description = "Create books from Markdown files";
      homepage = "https://rust-lang.github.io/mdBook/";
      license = lib.licenses.mpl20;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
toolboxLib.buildPackage { name = "mdbook"; dataPath = ./data.json; inherit builders; }
