{ pkgs, lib, toolbox, toolboxLib }:

# Tailscale's launcher for agentic coding tools through Aperture. Installs the
# `aperture` binary.
#
# Since 0.0.13 the two platforms ship differently: Linux gets goreleaser's flat
# tarball, macOS a zip holding the signed and notarized binary under
# `release/aperture_<os>_<arch>`. If a later release changes the layout again,
# add a builder variant rather than editing this one.
let
  isDarwin = platform: lib.hasPrefix "darwin" platform;

  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "aperture-cli";
    platforms = {
      "x86_64-linux"   = "linux_amd64";
      "aarch64-linux"  = "linux_arm64";
      "x86_64-darwin"  = "darwin_amd64";
      "aarch64-darwin" = "darwin_arm64";
    };
    url = { version, platform }:
      "https://github.com/tailscale/aperture-cli/releases/download/v${version}/"
      + (if isDarwin platform
         then "aperture_v${version}_${platform}.zip"
         else "aperture-cli_${platform}.tar.gz");
    sourceRoot = ".";
    binaries = [{
      from = { version, platform }:
        if isDarwin platform then "release/aperture_${platform}" else "aperture";
      to = "aperture";
    }];
    patchelf = false; # static Go binary (CGO_ENABLED=0)
    meta = {
      description = "Agentic coding launcher for Tailscale Aperture";
      homepage = "https://github.com/tailscale/aperture-cli";
      license = lib.licenses.bsd3;
      mainProgram = "aperture";
    };
  };
in
toolboxLib.buildPackage { name = "aperture-cli"; dataPath = ./data.json; inherit builders; }
