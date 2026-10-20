# Support code for Python applications built from a tagged GitHub source and
# upstream's committed uv.lock, via uv2nix.
#
# buildUvApplication returns a *builder function* (version: versionData:
# derivation) that slots into buildPackage's `builders` attrset, like
# buildRustPackage and buildGoPackage.
#
#   let
#     builders.default = toolboxLib.buildUvApplication {
#       inherit pkgs;
#       pname = "code-review-graph";
#       owner = "tirth8205";
#       repo  = "code-review-graph";
#       meta = { ... };
#     };
#   in toolboxLib.buildPackage { name = "code-review-graph"; dataPath = ./data.json; inherit builders; }
#
# The dependency tree is upstream's uv.lock, read as-is: every wheel and sdist
# in it is already pinned by hash, so data.json carries only the source hash.
# nixpkgs' python package set is not used, since its versions drift from
# upstream's tested ones.
#
# uv2nix parses the lock at evaluation time, so the source is fetched with
# `builtins.fetchTarball` (a hash-pinned eval-time fetch) rather than
# `fetchFromGitHub`, which would make this import-from-derivation. Both hash the
# unpacked tree, so `versionData.sha256` is the usual `--unpack` prefetch.
{ lib, pythonInputs }:

{
  # buildUvApplication { pkgs; pname; owner; repo; ... }
  #   -> version: versionData: derivation
  #
  # Required:
  #   pkgs       nixpkgs instance
  #   pname      package name; must match the uv project name
  #   owner      GitHub owner
  #   repo       GitHub repo
  # Optional:
  #   rev        fn { version } -> git rev (default: "v${version}")
  #   python     interpreter (default: pkgs.python3)
  #   overrides  pyproject-nix overlay (final: prev: { ... }) for wheels or
  #              sdists that need native fixes
  #   meta       derivation meta
  buildUvApplication =
    { pkgs
    , pname
    , owner
    , repo
    , rev ? ({ version }: "v${version}")
    , python ? pkgs.python3
    , overrides ? (_: _: { })
    , meta ? { }
    }:
    version: versionData:
    let
      inherit (
        if pythonInputs != null then
          pythonInputs
        else
          throw "buildUvApplication: toolboxLib was imported without pythonInputs"
      ) pyproject-nix uv2nix pyproject-build-systems;

      src = builtins.fetchTarball {
        url = "https://github.com/${owner}/${repo}/archive/${rev { inherit version; }}.tar.gz";
        sha256 = versionData.sha256;
      };

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };

      pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
          overrides
        ]
      );

      venv = pythonSet.mkVirtualEnv "${pname}-${version}-env" workspace.deps.default;
    in
    # mkApplication exposes only the project's own entry points, not the whole
    # venv's bin/ (python, pip, every dependency's scripts).
    ((pkgs.callPackages pyproject-nix.build.util { }).mkApplication {
      inherit venv;
      package = pythonSet.${pname};
    }).overrideAttrs (_: { inherit meta; });
}
