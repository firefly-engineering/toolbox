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

    # TypeScript 7 — the native Go compiler (`tsgo`), distributed as prebuilt
    # per-platform binaries under `@typescript/native-preview-<platform>`. Each
    # package ships `lib/tsgo` alongside the `lib.*.d.ts` standard library it
    # loads relative to its own real path, so the whole `lib/` tree stays
    # together and `bin/tsgo` is a symlink into it.
    tsgo = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platform = {
          "x86_64-linux"   = "linux-x64";
          "aarch64-linux"  = "linux-arm64";
          "x86_64-darwin"  = "darwin-x64";
          "aarch64-darwin" = "darwin-arm64";
        }.${system}
          or (throw "typescript ${version} (tsgo) has no binary for ${system}");
        platformData = versionData.${system}
          or (throw "typescript ${version} (tsgo) has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "typescript";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@typescript/native-preview-${platform}/-/native-preview-${platform}-${version}.tgz";
          hash = platformData.sha256;
        };

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        # Statically-linked Go binaries — no autoPatchelfHook needed on Linux.
        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/tsgo
          cp -r lib/. $out/lib/tsgo/

          mkdir -p $out/bin
          ln -s $out/lib/tsgo/tsgo $out/bin/tsgo

          runHook postInstall
        '';

        meta = with lib; {
          description = "TypeScript native compiler (tsgo, TypeScript 7 preview)";
          homepage = "https://www.typescriptlang.org";
          license = licenses.asl20;
          mainProgram = "tsgo";
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ];
        };
      };
  };
in
toolboxLib.buildPackage { name = "typescript"; dataPath = ./data.json; inherit builders; }
