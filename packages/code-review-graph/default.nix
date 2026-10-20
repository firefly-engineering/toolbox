{ pkgs, lib, toolbox, toolboxLib }:

# code-review-graph: a tree-sitter code graph of the current repository, served
# to agents over MCP (`code-review-graph serve`, stdio) and driven from the CLI
# (`build`, `update`, `status`, …). The graph lives in `.code-review-graph/` at
# the repository root.
#
# Built from upstream's uv.lock: nixpkgs' tree-sitter-language-pack (1.x) is
# outside upstream's `<1` pin. No optional extras (embeddings, wiki, …).
#
# Register it with agents through home-manager, never with upstream's
# `code-review-graph install`, which rewrites agent configs in place. The
# skills ship separately as `code-review-graph-skills`, from this data.json.
let
  builders.default = toolboxLib.buildUvApplication {
    inherit pkgs;
    pname = "code-review-graph";
    owner = "tirth8205";
    repo = "code-review-graph";
    # Upstream supports 3.10-3.13; its lock has no 3.14 wheels for watchdog.
    python = pkgs.python313;
    meta = {
      description = "Local-first code knowledge graph for token-efficient code review over MCP and CLI";
      homepage = "https://github.com/tirth8205/code-review-graph";
      license = lib.licenses.mit;
      mainProgram = "code-review-graph";
    };
  };
in
toolboxLib.buildPackage { name = "code-review-graph"; dataPath = ./data.json; inherit builders; }
