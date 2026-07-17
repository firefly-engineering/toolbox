{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        nodejs = toolbox.nodejs.versions.${toolbox.nodejs.default};
      in
      pkgs.stdenv.mkDerivation {
        pname = "typescript";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/typescript/-/typescript-${version}.tgz";
          hash = versionData.sha256;
        };

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/node_modules/typescript $out/bin
          cp -r . $out/lib/node_modules/typescript/

          cat > $out/bin/tsc <<'WRAPPER'
          #!/bin/sh
          exec ${nodejs}/bin/node "$(dirname "$0")/../lib/node_modules/typescript/bin/tsc" "$@"
          WRAPPER
          chmod +x $out/bin/tsc

          cat > $out/bin/tsserver <<'WRAPPER'
          #!/bin/sh
          exec ${nodejs}/bin/node "$(dirname "$0")/../lib/node_modules/typescript/bin/tsserver" "$@"
          WRAPPER
          chmod +x $out/bin/tsserver

          runHook postInstall
        '';

        meta = with lib; {
          description = "TypeScript language compiler and tools";
          homepage = "https://www.typescriptlang.org";
          license = licenses.asl20;
          mainProgram = "tsc";
        };
      };
  };
in
toolboxLib.buildPackage { name = "typescript"; dataPath = ./data.json; inherit builders; }
