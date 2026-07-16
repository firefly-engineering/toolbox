{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  # onnxruntime-node ships native libs for every OS inside one package; we keep
  # only the host's. These are the platform subdir names under bin/napi-v*/.
  onnxHostOs = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  onnxOtherOs = if pkgs.stdenv.hostPlatform.isDarwin then "linux" else "darwin";
  onnxOtherArch = if pkgs.stdenv.hostPlatform.isAarch64 then "x64" else "arm64";

  # Runtime fallback for the claude shim in postInstall: the user's PATH claude
  # wins, but with none present we exec this pinned nixpkgs claude-code so the SDK
  # still works out of the box. claude-code is unfree, so we scope allowUnfree to
  # just this package — the rest of the toolbox stays free and consumers needn't
  # set allowUnfree. Pulls claude-code (~73 MiB; shares nodejs) into the closure.
  claudeCode = (import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfreePredicate = p: lib.getName p == "claude-code";
  }).claude-code;

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
        #
        # Then trim ~0.5 GiB the dev-prune can't touch (all production deps): the
        # Claude Agent SDK's vendored per-platform `claude` (~231 MiB) and ONNX
        # runtime binaries that cannot run on the host.
        postInstall = ''
          nm="$out/lib/node_modules/@agentmemory/agentmemory/node_modules"

          # Use an external claude instead of the SDK's bundled Bun binary.
          # sdk.mjs resolves `@anthropic-ai/claude-agent-sdk-<plat>/claude` via
          # require.resolve; because that path has no .js extension the SDK spawns
          # it directly (`ui=aZ(a); command=ui?a:n`), so this shim picks which
          # claude to run: the user's PATH claude if present (their terminal one),
          # else the pinned nixpkgs claude-code baked in below. Only the
          # claude-backed features use it, not memory storage/search.
          for pdir in "$nm"/@anthropic-ai/claude-agent-sdk-*; do
            [ -e "$pdir/claude" ] || continue
            rm -f "$pdir/claude"
            printf '#!/bin/sh\nif command -v claude >/dev/null 2>&1; then exec claude "$@"; fi\nexec ${lib.getExe claudeCode} "$@"\n' > "$pdir/claude"
            chmod +x "$pdir/claude"
          done

          # onnxruntime-node bundles every OS/arch in one package; drop the Windows
          # blobs, the non-host OS and non-host CPU arch, plus the browser WASM
          # build (onnxruntime-web). Then drop the WASM backend + source maps that
          # transformers.js bundles in its own dist — all unused once we run on the
          # native onnxruntime-node backend. Host local-embedding support stays
          # intact; the CLI and memory storage/search are unaffected.
          find "$nm" -type d -name onnxruntime-web -prune -exec rm -rf {} +
          find "$nm" -type d \
            \( -path "*/onnxruntime-node/bin/*/win32" \
            -o -path "*/onnxruntime-node/bin/*/${onnxOtherOs}" \
            -o -path "*/onnxruntime-node/bin/*/*/${onnxOtherArch}" \) \
            -prune -exec rm -rf {} +
          rm -f "$nm"/@xenova/transformers/dist/ort-wasm*.wasm \
                "$nm"/@xenova/transformers/dist/*.map
        '';

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
