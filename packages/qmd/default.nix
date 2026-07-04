{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  system = pkgs.stdenv.hostPlatform.system;

  # qmd is a Bun/TypeScript app. Adapted from upstream's flake.nix:
  # a fixed-output `node_modules` derivation (bun install over the frozen
  # lockfile) feeds the main build, which compiles the better-sqlite3 native
  # addon with node-gyp and wraps `bun src/cli/qmd.ts`. node_modules content is
  # platform-specific (optional sqlite-vec/native deps), so its hash is keyed by
  # system in data.json.
  builders = {
    default = version: versionData:
      let
        nodeModulesHash = versionData.nodeModules.${system}
          or (throw "qmd ${version} has no node_modules hash for ${system}");

        src = pkgs.fetchFromGitHub {
          owner = "tobi";
          repo = "qmd";
          rev = "v${version}";
          hash = versionData.sha256;
        };

        nodeModules = pkgs.stdenvNoCC.mkDerivation {
          pname = "qmd-node-modules";
          inherit version src;

          impureEnvVars = pkgs.lib.fetchers.proxyImpureEnvVars ++ [
            "GIT_PROXY_COMMAND"
            "SOCKS_SERVER"
          ];

          nativeBuildInputs = [ pkgs.bun ];
          dontConfigure = true;

          buildPhase = ''
            export HOME=$(mktemp -d)
            bun install \
              --backend copyfile \
              --frozen-lockfile \
              --ignore-scripts \
              --no-progress \
              --production
          '';

          installPhase = ''
            mkdir -p $out
            cp -R node_modules $out/
          '';

          dontFixup = true;
          outputHash = nodeModulesHash;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        };
      in
      pkgs.stdenv.mkDerivation {
        pname = "qmd";
        inherit version src;

        nativeBuildInputs = [
          pkgs.bun
          pkgs.makeWrapper
          pkgs.nodejs
          pkgs.node-gyp
          pkgs.python3 # node-gyp compiles better-sqlite3
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          pkgs.cctools # libtool for node-gyp on macOS
          pkgs.xcbuild # xcodebuild/xcrun shims so node-gyp's Xcode/CLT probe passes
        ];

        buildInputs = [ pkgs.sqlite ];

        buildPhase = ''
          runHook preBuild

          export HOME=$(mktemp -d)
          cp -R ${nodeModules}/node_modules ./
          chmod -R u+w node_modules
          (cd node_modules/better-sqlite3 && node-gyp rebuild --release)

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/qmd $out/bin
          cp -r node_modules $out/lib/qmd/
          cp -r src $out/lib/qmd/
          cp package.json $out/lib/qmd/

          makeWrapper ${pkgs.bun}/bin/bun $out/bin/qmd \
            --add-flags "$out/lib/qmd/src/cli/qmd.ts" \
            --set DYLD_LIBRARY_PATH "${pkgs.sqlite.out}/lib" \
            --set LD_LIBRARY_PATH "${pkgs.sqlite.out}/lib"

          runHook postInstall
        '';

        dontStrip = true;

        meta = with lib; {
          description = "Query Markup Documents: on-device hybrid search for markdown (BM25, vector, LLM rerank)";
          homepage = "https://github.com/tobi/qmd";
          license = licenses.mit;
          mainProgram = "qmd";
          # node_modules hashes only populated/verified for these systems.
          platforms = [ "x86_64-linux" "aarch64-darwin" ];
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "qmd" builders versions;
  default = meta.default;
}
