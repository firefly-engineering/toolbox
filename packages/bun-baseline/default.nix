{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "bun-baseline";
    # Upstream ships baseline builds (no AVX2 requirement) for x86 only. The
    # table is the single declaration of that: it resolves the asset, and it
    # states meta.platforms, so the registry filters this package out on the
    # other systems rather than throwing.
    platforms = {
      "x86_64-linux" = "linux-x64-baseline";
      "x86_64-darwin" = "darwin-x64-baseline";
    };
    url = { version, platform }:
      "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-${platform}.zip";
    sourceRoot = { version, platform }: "bun-${platform}";
    binaries = [ "bun" ];
    symlinks.bunx = "bun";
    meta = {
      description = "Bun JavaScript runtime (baseline build, no AVX2 requirement)";
      homepage = "https://bun.sh";
      license = lib.licenses.mit;
    };
  };
in
toolboxLib.buildPackage { name = "bun-baseline"; dataPath = ./data.json; inherit builders; }
