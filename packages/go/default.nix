{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  # Attributes expected by buildGoModule when overriding `go`
  GOOS = pkgs.go.GOOS;
  GOARCH = pkgs.go.GOARCH;
  CGO_ENABLED = pkgs.go.CGO_ENABLED;

  builders = {
    default = version: versionData:
      pkgs.stdenv.mkDerivation {
        pname = "go";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://go.dev/dl/go${version}.src.tar.gz";
          hash = versionData.sha256;
        };

        nativeBuildInputs = [ pkgs.go ];
        GOROOT_BOOTSTRAP = "${pkgs.go}/share/go";

        buildPhase = ''
          export HOME=$TMPDIR
          cd src
          bash make.bash
          cd ..
        '';

        installPhase = ''
          mkdir -p $out/share/go $out/bin
          cp -a . $out/share/go/
          ln -s $out/share/go/bin/go $out/bin/go
          ln -s $out/share/go/bin/gofmt $out/bin/gofmt
        '';

        passthru = {
          inherit GOOS GOARCH CGO_ENABLED;
        };

        meta = {
          platforms = pkgs.go.meta.platforms;
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "go" builders versions;
  default = meta.default;
}
