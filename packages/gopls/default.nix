{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildGoPackage {
    inherit pkgs toolbox;
    pname = "gopls";
    owner = "golang";
    repo = "tools";
    rev = { version }: "gopls/v${version}";
    extraArgs.sourceRoot = "source/gopls";
    meta = with lib; {
      description = "Official Go language server";
      homepage = "https://pkg.go.dev/golang.org/x/tools/gopls";
      license = licenses.bsd3;
      mainProgram = "gopls";
    };
  };
in
toolboxLib.buildPackage { name = "gopls"; dataPath = ./data.json; inherit builders; }
