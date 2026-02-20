{ pkgs, lib, toolbox }:

let
  data = builtins.fromJSON (builtins.readFile ./data.json);
  meta = data._meta;
  versionEntries = lib.filterAttrs (n: _: n != "_meta") data;

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

  buildVersion = version: versionData:
    let
      builderName = versionData.builder or "default";
      builder = builders.${builderName}
        or (throw "Unknown builder '${builderName}' for beads ${version}");
    in
    builder version versionData;
in
{
  versions = builtins.mapAttrs buildVersion versionEntries;
  default = meta.default;
}
