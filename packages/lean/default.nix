{ pkgs, lib, toolbox, toolboxLib }:

# Lean 4 (`lean`, `lake`, `leanc`), built from source. nixpkgs' lean4 recipe is
# reused; only the source moves to the pinned tag. Upstream's prebuilt Linux
# release links compiled programs against its own bundled glibc stubs, which do
# not run in the Nix sandbox.
let
  builders.default = version: versionData:
    pkgs.lean4.overrideAttrs (old: rec {
      inherit version;
      src = pkgs.fetchFromGitHub {
        owner = "leanprover";
        repo = "lean4";
        tag = "v${version}";
        hash = versionData.sha256;
      };

      # Lean 4.33 fetches mimalloc with FetchContent, so nixpkgs'
      # ExternalProject patch no longer applies: point FetchContent at the
      # vendored source, and the runtime's hardcoded paths at it too.
      patches = [ ];
      postPatch = ''
        substituteInPlace src/CMakeLists.txt \
          --replace-fail 'set(GIT_SHA1 "")' 'set(GIT_SHA1 "${src.tag}")'
        for file in stage0/src/CMakeLists.txt stage0/src/runtime/CMakeLists.txt src/CMakeLists.txt src/runtime/CMakeLists.txt; do
          substituteInPlace "$file" \
            --replace-fail "\''${LEAN_BINARY_DIR}/../mimalloc/src/mimalloc" '${old.mimalloc-src}'
        done
      '';
      # 4.33 links OpenSSL (stage0 configure requires >= 3).
      buildInputs = old.buildInputs ++ [ pkgs.openssl ];
      cmakeFlags = old.cmakeFlags ++ [ "-DFETCHCONTENT_SOURCE_DIR_MIMALLOC=${old.mimalloc-src}" ];
    });
in
toolboxLib.buildPackage { name = "lean"; dataPath = ./data.json; inherit builders; }
