{ pkgs, lib, toolbox, toolboxLib }:

let
  # The asset extension varies by platform, so it is folded into the platform
  # string and split back out when building the URL — the same idiom
  # packages/gh uses. buildPrebuiltBinary keys its auto-unzip off the URL.
  extOf = platform: if lib.hasSuffix ".zip" platform then "zip" else "tar.gz";

  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "git-lfs";
    platforms = {
      "x86_64-linux" = "linux-amd64.tar.gz";
      "aarch64-linux" = "linux-arm64.tar.gz";
      "x86_64-darwin" = "darwin-amd64.zip";
      "aarch64-darwin" = "darwin-arm64.zip";
    };
    url = { version, platform }:
      let
        ext = extOf platform;
        suffix = lib.removeSuffix ".${ext}" platform;
      in
      "https://github.com/git-lfs/git-lfs/releases/download/v${version}/git-lfs-${suffix}-v${version}.${ext}";
    sourceRoot = { version, platform }: "git-lfs-${version}";
    binaries = [ "git-lfs" ];
    postInstall = ''
      installManPage man/man1/*.1 man/man5/*.5 man/man7/*.7
    '';
    meta = with lib; {
      description = "Git extension for versioning large files";
      homepage = "https://git-lfs.com";
      license = licenses.mit;
      mainProgram = "git-lfs";
    };
  };
in
toolboxLib.buildPackage { name = "git-lfs"; dataPath = ./data.json; inherit builders; }
