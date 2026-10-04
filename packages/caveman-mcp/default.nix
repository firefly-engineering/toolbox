{ pkgs, lib, toolbox, toolboxLib }:

# Caveman's MCP server over stdio: `caveman_retrieve` (plus compress/stats/TOON
# tools) on the shared recovery store, `$CAVEMAN_CCR_DB` else
# `$CAVEMAN_HOME/ccr.db` (default `~/.caveman/ccr.db`). It is the agent-side
# recovery path `caveman-proxy` requires before it compresses streaming or
# subscription traffic: registered in Claude Code as server `caveman`, its tool
# appears as `mcp__caveman__caveman_retrieve`.
#
# Proxy and MCP server read and write the same ccr.db, so they are pinned to the
# same `bin-v<version>` release: bump them together, never independently.
let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "caveman-mcp";
    platforms = {
      "x86_64-linux"   = "linux_amd64";
      "aarch64-linux"  = "linux_arm64";
      "x86_64-darwin"  = "darwin_amd64";
      "aarch64-darwin" = "darwin_arm64";
    };
    url = { version, platform }:
      "https://github.com/JuliusBrussee/caveman/releases/download/bin-v${version}/caveman-mcp_${platform}";
    binaries = [ "caveman-mcp" ];
    patchelf = false; # static Go binary
    meta = {
      description = "Caveman MCP server: context recovery and compression tools over stdio";
      homepage = "https://github.com/JuliusBrussee/caveman/tree/main/mcp";
      license = lib.licenses.asl20;
      mainProgram = "caveman-mcp";
    };
  };
in
toolboxLib.buildPackage { name = "caveman-mcp"; dataPath = ./data.json; inherit builders; }
