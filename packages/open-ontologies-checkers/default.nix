{ pkgs, lib, toolbox, toolboxLib }:

# open-ontologies' proof checkers (`oo-cert`, `oo-horn`, `oo-shacl`,
# `oo-folmodel`, …), built from the Lean project under `lean/`. The engine's
# certified paths (closure diff, FOL solve, verified SHACL) run them from
# `$PATH`, and an auditor re-checks an archived certificate with them alone.
# Upstream releases only a subset, for x86_64-linux only.
#
# The pin is read from `packages/open-ontologies/data.json`, so the checkers
# never verify a different version's certificate format. `lean` there is the
# toolbox Lean matching upstream's `lean/lean-toolchain`.
let
  builders.default = version: versionData:
    pkgs.stdenv.mkDerivation {
      pname = "open-ontologies-checkers";
      inherit version;

      src = pkgs.fetchFromGitHub {
        inherit (versionData) owner repo rev;
        hash = versionData.sha256;
      };
      sourceRoot = "source/lean";

      nativeBuildInputs = [ toolbox.lean.versions.${versionData.lean} ];

      buildPhase = ''
        runHook preBuild
        export HOME=$TMPDIR
        lake build
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        # Lake leaves .hash/.rsp/.trace build records next to each executable.
        find .lake/build/bin -maxdepth 1 -type f ! -name "*.*" -exec install -Dm755 -t $out/bin {} +
        runHook postInstall
      '';

      meta = {
        description = "Lean proof checkers for open-ontologies certificates";
        homepage = "https://github.com/fabio-rovai/open-ontologies/tree/main/lean";
        license = lib.licenses.mit;
      };
    };
in
toolboxLib.buildPackage {
  name = "open-ontologies-checkers";
  dataPath = ../open-ontologies/data.json;
  inherit builders;
}
