{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildGoPackage {
    inherit pkgs toolbox;
    pname = "beads";
    owner = "steveyegge";
    repo = "beads";
    subPackages = [ "cmd/bd" ];
    extraArgs = { go, ... }: {
      # Upstream's go.mod pins a toolchain line newer than the pinned Go;
      # rewrite it to what we actually build with.
      postPatch = ''
        goVer="$(${go}/bin/go env GOVERSION | sed 's/^go//')"
        sed -i "s/^go .*/go $goVer/" go.mod
      '';
      env.GOTOOLCHAIN = "auto";
      nativeBuildInputs = [ pkgs.git pkgs.pkg-config ];
      buildInputs = [ pkgs.icu ];

      postInstall = ''
        ln -s bd $out/bin/beads
        mkdir -p $out/share/{fish/vendor_completions.d,bash-completion/completions,zsh/site-functions}
        $out/bin/bd completion fish > $out/share/fish/vendor_completions.d/bd.fish
        $out/bin/bd completion bash > $out/share/bash-completion/completions/bd
        $out/bin/bd completion zsh > $out/share/zsh/site-functions/_bd
      '';
    };
    meta = with lib; {
      description = "An issue tracker designed for AI-supervised coding workflows";
      homepage = "https://github.com/steveyegge/beads";
      license = licenses.mit;
      mainProgram = "bd";
    };
  };
in
toolboxLib.buildPackage { name = "beads"; dataPath = ./data.json; inherit builders; }
