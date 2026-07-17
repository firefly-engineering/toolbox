{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "just";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-musl";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/casey/just/releases/download/${version}/just-${version}-${platform}.tar.gz";
    binaries = [ "just" ];
    sourceRoot = ".";
    postInstall = ''
      installManPage just.1
      installShellCompletion completions/just.{bash,fish,zsh}
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
in
toolboxLib.buildPackage { name = "just"; dataPath = ./data.json; inherit builders; }
