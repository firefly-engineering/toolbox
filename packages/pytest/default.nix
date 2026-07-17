{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        pythonPkgs = pkgs.python3Packages;
        pytest = pythonPkgs.pytest.overridePythonAttrs (old: {
          inherit version;
          src = pkgs.fetchPypi {
            pname = "pytest";
            inherit version;
            hash = versionData.sha256;
          };
        });
      in
      pkgs.runCommand "pytest-${version}" { meta = with lib; {
        description = "Python testing framework";
        homepage = "https://pytest.org";
        license = licenses.mit;
        mainProgram = "pytest";
      }; } ''
        mkdir -p $out/bin
        ln -s ${pytest}/bin/pytest $out/bin/pytest
        ln -s ${pytest}/bin/py.test $out/bin/py.test
      '';
  };
in
toolboxLib.buildPackage { name = "pytest"; dataPath = ./data.json; inherit builders; }
