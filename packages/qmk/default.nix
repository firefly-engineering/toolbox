{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

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
{
  versions = toolboxLib.buildVersions "qmk" builders versions;
  default = meta.default;
}
