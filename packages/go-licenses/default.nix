{ pkgs, lib, toolbox, toolboxLib }:

let
  mkBuilder = extraArgs: toolboxLib.buildGoPackage {
    inherit pkgs toolbox extraArgs;
    pname = "go-licenses";
    owner = "google";
    repo = "go-licenses";
    meta = with lib; {
      description = "Reports on the licenses used by a Go package and its dependencies";
      homepage = "https://github.com/google/go-licenses";
      license = licenses.asl20;
      mainProgram = "go-licenses";
    };
  };

  builders = {
    default = mkBuilder { };
    legacy = mkBuilder { proxyVendor = true; };
  };
in
toolboxLib.buildPackage { name = "go-licenses"; dataPath = ./data.json; inherit builders; }
