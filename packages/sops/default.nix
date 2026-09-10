{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "sops";
    platforms = {
      "x86_64-linux" = "linux.amd64";
      "aarch64-linux" = "linux.arm64";
      "x86_64-darwin" = "darwin.amd64";
      "aarch64-darwin" = "darwin.arm64";
    };
    url =
      { version, platform }:
      "https://github.com/getsops/sops/releases/download/v${version}/sops-v${version}.${platform}";
    binaries = [ "sops" ];
    # Statically linked Go binary — nothing for autoPatchelfHook to resolve.
    patchelf = false;
    meta = {
      description = "Simple and flexible tool for managing secrets";
      homepage = "https://getsops.io";
      license = lib.licenses.mpl20;
      mainProgram = "sops";
    };
  };
in
toolboxLib.buildPackage {
  name = "sops";
  dataPath = ./data.json;
  inherit builders;
}
