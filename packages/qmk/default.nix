{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      pkgs.qmk.overridePythonAttrs (old: {
        inherit version;
        src = pkgs.fetchPypi {
          pname = "qmk";
          inherit version;
          hash = versionData.sha256;
        };
        patches = (old.patches or [ ]) ++ toolboxLib.resolvePatches ./. versionData;
        propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
          pkgs.dos2unix
          pkgs.dfu-util
        ];
      });
  };
in
toolboxLib.buildPackage { name = "qmk"; dataPath = ./data.json; inherit builders; }
