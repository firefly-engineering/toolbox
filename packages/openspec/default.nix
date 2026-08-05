{ pkgs, lib, toolbox, toolboxLib }:

let
  # OpenSpec is a pnpm/TypeScript CLI. We build from the tagged GitHub source so
  # that dependencies are pinned by upstream's own committed `pnpm-lock.yaml` —
  # resolved once, by upstream, and fetched reproducibly by `fetchPnpmDeps` (a
  # fixed-output derivation keyed on `pnpmDeps` in data.json). No dependency
  # versions are resolved at our build time; a stale lock fails the build rather
  # than drifting. The pnpm used to install is toolbox's own pinned pnpm
  # (data-driven via the `pnpm` field) rather than nixpkgs' — upstream's
  # `packageManager: pnpm@9.15.9` is EOL and marked insecure in nixpkgs, while
  # the lockfile is `lockfileVersion: '9.0'`, which pnpm 11 reads natively.
  #
  # The npm registry tarball ships a prebuilt `dist/` but no lockfile, so it is
  # deliberately NOT used — building from source is what lets us honor the lock.
  builders = {
    default = version: versionData:
      let
        pnpm = toolbox.pnpm.versions.${versionData.pnpm};
      in
      pkgs.buildNpmPackage (finalAttrs: {
        pname = "openspec";
        inherit version;

        src = pkgs.fetchFromGitHub {
          owner = "Fission-AI";
          repo = "OpenSpec";
          rev = "v${version}";
          hash = versionData.sha256;
        };

        # Drive dependency install with pnpm (and its lockfile), not npm.
        npmDeps = null;
        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (finalAttrs) pname version src;
          inherit pnpm;
          fetcherVersion = 4;
          hash = versionData.pnpmDeps;
        };
        nativeBuildInputs = [ pnpm ];
        npmConfigHook = pkgs.pnpmConfigHook;

        # `npm run build` executes the package-manager-agnostic `node build.js`
        # (compiles TypeScript → dist/). node_modules is pnpm-managed, so leave
        # npm's dev-prune out of it.
        dontNpmPrune = true;

        meta = with lib; {
          description = "AI-native system for spec-driven development";
          homepage = "https://github.com/Fission-AI/OpenSpec";
          license = licenses.mit;
          mainProgram = "openspec";
          platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        };
      });
  };
in
toolboxLib.buildPackage { name = "openspec"; dataPath = ./data.json; inherit builders; }
