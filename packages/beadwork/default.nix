{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      let
        go = toolbox.go.versions.${versionData.go};
      in
      (pkgs.buildGoModule.override { inherit go; }) {
        pname = "beadwork";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "jallum";
          repo = "beadwork";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        vendorHash = versionData.vendorHash;
        subPackages = [ "cmd/bw" ];
        doCheck = false;

        postPatch = ''
          goVer="$(${go}/bin/go env GOVERSION | sed 's/^go//')"
          sed -i "s/^go .*/go $goVer/" go.mod
        '';
        env.GOTOOLCHAIN = "auto";
        nativeBuildInputs = [ pkgs.git ];

        meta = with lib; {
          description = "A git-native work management tool for AI coding agents";
          homepage = "https://github.com/jallum/beadwork";
          license = licenses.mit;
          mainProgram = "bw";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "beadwork" builders versions;
  default = meta.default;
}
