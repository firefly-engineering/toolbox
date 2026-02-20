{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      let
        go = toolbox.go.versions.${versionData.go};
      in
      (pkgs.buildGoModule.override { inherit go; }) {
        pname = "beads";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "steveyegge";
          repo = "beads";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        vendorHash = versionData.vendorHash;
        subPackages = [ "cmd/bd" ];
        doCheck = false;

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

        meta = with lib; {
          description = "An issue tracker designed for AI-supervised coding workflows";
          homepage = "https://github.com/steveyegge/beads";
          license = licenses.mit;
          mainProgram = "bd";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "beads" builders versions;
  default = meta.default;
}
