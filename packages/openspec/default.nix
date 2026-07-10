{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  # OpenSpec is a pnpm/TypeScript CLI. We build from the tagged GitHub source so
  # that dependencies are pinned by upstream's own committed `pnpm-lock.yaml` —
  # resolved once, by upstream, and fetched reproducibly by `fetchPnpmDeps` (a
  # fixed-output derivation keyed on `pnpmDeps` in data.json). No dependency
  # versions are resolved at our build time; a stale lock fails the build rather
  # than drifting. pnpm_9 matches upstream's `packageManager: pnpm@9.15.9`.
  #
  # The npm registry tarball ships a prebuilt `dist/` but no lockfile, so it is
  # deliberately NOT used — building from source is what lets us honor the lock.
  builders = {
    default = version: versionData:
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
          pnpm = pkgs.pnpm_9;
          fetcherVersion = 3;
          hash = versionData.pnpmDeps;
        };
        nativeBuildInputs = [ pkgs.pnpm_9 ];
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
{
  versions = toolboxLib.buildVersions "openspec" builders versions;
  default = meta.default;
}
