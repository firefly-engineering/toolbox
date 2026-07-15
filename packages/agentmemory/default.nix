{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  # agentmemory is a TypeScript CLI + MCP server bundled with tsdown. It runs on
  # the pure-JS "iii engine" (iii-sdk is an ordinary npm dep — there is no
  # external daemon or binary to fetch), so a plain Node package is enough.
  #
  # We build from the tagged GitHub source, not the npm tarball: the tarball ships
  # only a prebuilt `dist/` and, like the repo itself, NO lockfile. Upstream
  # commits no lockfile anywhere, so per AGENTS.md we fall back to the documented
  # last resort — a vendored, version-namespaced lockfile generated with
  # `npm install --package-lock-only --ignore-scripts`. It pins *a* dependency
  # tree rather than upstream's *tested* one (strictly worse than an upstream
  # lock), but it is the only way to keep the build reproducible: `npm ci`
  # verifies it and fails loudly instead of re-resolving `^`/`~` ranges at build
  # time. fetchNpmDeps (a FOD keyed on npmDepsHash) fetches it reproducibly, and
  # postPatch injects it so both the dep fetch and the build see it.
  builders = {
    default = version: versionData:
      pkgs.buildNpmPackage (finalAttrs: {
        pname = "agentmemory";
        inherit version;

        src = pkgs.fetchFromGitHub {
          owner = "rohitg00";
          repo = "agentmemory";
          rev = "v${version}";
          hash = versionData.sha256;
        };

        # Upstream has no lockfile; drop in our vendored, version-namespaced one so
        # `npm ci` has a fully-resolved tree to verify. buildNpmPackage forwards
        # postPatch to fetchNpmDeps, so the fetcher sees the lock too.
        postPatch = ''
          cp ${./. + "/package-lock-${version}.json"} package-lock.json
        '';
        npmDepsHash = versionData.npmDepsHash;

        # The native optional deps (onnxruntime-node, @node-rs/jieba, and sharp via
        # @xenova/transformers — for local embeddings / CLIP / reranking) all ship
        # prebuilt binaries in per-platform packages or in their own tarballs, so
        # nothing needs a node-gyp rebuild. `npm ci` already runs --ignore-scripts;
        # skip scripts on the rebuild pass too so sharp's libvips CDN download does
        # not try to reach the network in the sandbox. The affected features
        # degrade gracefully when the binary is absent (e.g. non-x86_64/aarch64
        # platforms); the API/MCP server and default search are unaffected.
        npmRebuildFlags = [ "--ignore-scripts" ];

        # node_modules is npm-managed; the default dev-prune keeps the runtime
        # closure (the neverBundle'd @anthropic-ai/* SDKs and native deps) while
        # dropping build-only tooling.

        meta = with lib; {
          description = "Persistent memory system for AI coding agents (CLI + MCP server)";
          homepage = "https://www.agent-memory.dev/";
          license = licenses.asl20;
          mainProgram = "agentmemory";
          platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        };
      });
  };
in
{
  versions = toolboxLib.buildVersions "agentmemory" builders versions;
  default = meta.default;
}
