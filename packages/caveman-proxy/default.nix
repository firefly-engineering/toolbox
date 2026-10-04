{ pkgs, lib, toolbox, toolboxLib }:

# Caveman's standalone gateway: a base-URL-swap reverse proxy for LLM traffic
# (record mode by default; `mode: compress` in caveman.yaml compresses
# in-process). Point an agent at it with e.g.
# `ANTHROPIC_BASE_URL=http://127.0.0.1:8787`.
#
# Upstream releases its Go binaries under `bin-v<version>` tags, separate from
# the `v<version>` tags of the skills (see `caveman-skills`). The Node `caveman`
# CLI that wraps this binary (`caveman start`/`wrap`/`learn`) is not packaged.
#
# `caveman-mcp` shares this binary's ccr.db and is pinned to the same release:
# bump the two together, never independently.
let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "caveman-proxy";
    platforms = {
      "x86_64-linux"   = "linux_amd64";
      "aarch64-linux"  = "linux_arm64";
      "x86_64-darwin"  = "darwin_amd64";
      "aarch64-darwin" = "darwin_arm64";
    };
    url = { version, platform }:
      "https://github.com/JuliusBrussee/caveman/releases/download/bin-v${version}/caveman-proxy_${platform}";
    binaries = [ "caveman-proxy" ];
    patchelf = false; # static Go binary
    meta = {
      description = "Caveman gateway: local LLM proxy with truthful metering and context compression";
      homepage = "https://docs.caveman.so/docs/proxy";
      license = lib.licenses.asl20;
      mainProgram = "caveman-proxy";
    };
  };
in
toolboxLib.buildPackage { name = "caveman-proxy"; dataPath = ./data.json; inherit builders; }
