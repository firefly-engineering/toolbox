{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildGoPackage {
    inherit pkgs toolbox;
    pname = "beads-viewer";
    owner = "Dicklesworthstone";
    repo = "beads_viewer";
    subPackages = [ "cmd/bv" ];
    extraArgs = { version, go, ... }: {
      # Upstream's go.mod pins a toolchain line newer than the pinned Go;
      # rewrite it to what we actually build with.
      postPatch = ''
        goVer="$(${go}/bin/go env GOVERSION | sed 's/^go//')"
        sed -i "s/^go .*/go $goVer/" go.mod
      '';
      env.GOTOOLCHAIN = "auto";
      ldflags = [ "-X" "github.com/Dicklesworthstone/beads_viewer/pkg/version.Version=v${version}" ];
    };
    meta = with lib; {
      description = "Terminal UI for the Beads issue tracker with dependency graph visualization";
      homepage = "https://github.com/Dicklesworthstone/beads_viewer";
      license = licenses.mit;
      mainProgram = "bv";
    };
  };
in
toolboxLib.buildPackage { name = "beads-viewer"; dataPath = ./data.json; inherit builders; }
