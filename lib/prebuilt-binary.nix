# Support code for packaging tools distributed as prebuilt per-platform
# binaries or archives (no source build).
#
# buildPrebuiltBinary returns a *builder function* (version: versionData:
# derivation) that slots into buildPackage's `builders` attrset — it does not
# read data.json itself. So a prebuilt package is still assembled through
# buildPackage and can grow additional builder variants like any other:
#
#   let
#     builders.default = toolboxLib.buildPrebuiltBinary {
#       inherit pkgs;
#       pname     = "jq";
#       platforms = { "x86_64-linux" = "linux-amd64"; ... };  # system -> asset
#       url       = { version, platform }: "https://.../jq-${platform}";
#       binaries  = [ "jq" ];
#     };
#   in toolboxLib.buildPackage { name = "jq"; dataPath = ./data.json; inherit builders; }
#
# It hides the invariant ritual (per-system asset resolution with a throw on
# unsupported platforms, fetchurl against versionData.<system>.sha256, the
# dontConfigure/dontBuild/dontStrip trio, optional Linux autoPatchelfHook, and
# installing named executables into $out/bin). Tools that install a whole
# toolchain tree (nodejs, python, rust, git, platform-tools) are a different
# concept and stay on plain mkDerivation.
{ lib }:

{
  # buildPrebuiltBinary { pkgs; pname; platforms; url; binaries; ... }
  #   -> version: versionData: derivation
  #
  # Required:
  #   pkgs       nixpkgs instance
  #   pname      package name
  #   platforms  attrset  system -> asset string (throws on unsupported system)
  #   url        fn { version, platform } -> download URL string
  #   binaries   list of executables to install 0755 into $out/bin. Each entry
  #              is either a string (a path relative to sourceRoot, installed
  #              under its basename) or { from; to; } to rename on install —
  #              `from` may be a string or a fn { version, platform } -> string
  #              (for assets whose binary is named e.g. tool-${version}-${triple}).
  #              For a single raw binary (sourceRoot = null) `from` is ignored
  #              and $src is installed under `to`/basename.
  # Optional:
  #   sourceRoot null -> the asset is a single binary (dontUnpack). A transport
  #              compression suffix (.zst/.gz/.xz/.bz2) is auto-detected and the
  #              binary decompressed into $out/bin; otherwise $src is installed
  #              as-is. A non-null value (a string, or fn { version, platform } ->
  #              string) names the unpacked directory ("." for a flat tarball).
  #   patchelf   run autoPatchelfHook + cc.cc.lib on Linux (default true; set
  #              false for static binaries)
  #   extraLibs  additional shared libraries the binary links against, for
  #              autoPatchelfHook to resolve on Linux (e.g. [ pkgs.zlib ] when
  #              the asset wants libz.so.1). Ignored when patchelf is false.
  #   symlinks   attrset  link -> target, creating $out/bin/<link> -> $out/bin/<target>
  #   postInstall  extra shell appended inside installPhase (completions, man
  #              pages, shipped asset trees, relative symlinks, …)
  #   meta       derivation meta
  buildPrebuiltBinary =
    { pkgs
    , pname
    , platforms
    , url
    , binaries
    , sourceRoot ? null
    , patchelf ? true
    , extraLibs ? [ ]
    , symlinks ? { }
    , postInstall ? ""
    , meta ? { }
    }:
    version: versionData:
    let
      system = pkgs.stdenv.hostPlatform.system;
      onLinux = pkgs.stdenv.hostPlatform.isLinux;

      platform = platforms.${system}
        or (throw "${pname} ${version} has no binary for ${system}");
      platformData = versionData.${system}
        or (throw "${pname} ${version} has no binary for ${system}");

      theUrl = url { inherit version platform; };
      isZip = lib.hasSuffix ".zip" theUrl;

      unpacked = sourceRoot != null;
      resolvedSourceRoot =
        if lib.isFunction sourceRoot then sourceRoot { inherit version platform; }
        else sourceRoot;

      # A single raw binary (sourceRoot = null) may arrive transport-compressed;
      # pick the decompressor by suffix, mirroring the .zip auto-unzip above. An
      # unpacked archive (.tar.gz etc.) is handled by stdenv, not here.
      decompressor =
        if unpacked then null
        else if lib.hasSuffix ".zst" theUrl then { pkg = pkgs.zstd; cmd = "zstd -dc"; }
        else if lib.hasSuffix ".gz" theUrl then { pkg = pkgs.gzip; cmd = "gzip -dc"; }
        else if lib.hasSuffix ".xz" theUrl then { pkg = pkgs.xz; cmd = "xz -dc"; }
        else if lib.hasSuffix ".bz2" theUrl then { pkg = pkgs.bzip2; cmd = "bzip2 -dc"; }
        else null;

      installBins = lib.concatMapStringsSep "\n" (b:
        let
          fromRaw = if lib.isAttrs b then b.from else b;
          fromPath = if lib.isFunction fromRaw then fromRaw { inherit version platform; } else fromRaw;
          to = if lib.isAttrs b then b.to else baseNameOf fromPath;
          installSrc = if unpacked then fromPath else "$src";
        in
        if decompressor != null then
          "${decompressor.cmd} $src > $out/bin/${to}\n        chmod +x $out/bin/${to}"
        else
          "install -m755 ${installSrc} $out/bin/${to}"
      ) binaries;

      mkSymlinks = lib.concatStringsSep "\n" (lib.mapAttrsToList (link: target:
        "ln -s $out/bin/${target} $out/bin/${link}"
      ) symlinks);
    in
    pkgs.stdenv.mkDerivation ({
      inherit pname version meta;

      src = pkgs.fetchurl {
        url = theUrl;
        hash = platformData.sha256;
      };

      dontConfigure = true;
      dontBuild = true;
      dontStrip = true;

      nativeBuildInputs =
        [ pkgs.installShellFiles ]
        ++ lib.optionals isZip [ pkgs.unzip ]
        ++ lib.optionals (decompressor != null) [ decompressor.pkg ]
        ++ lib.optionals (patchelf && onLinux) [ pkgs.autoPatchelfHook ];
      buildInputs = lib.optionals (patchelf && onLinux) ([ pkgs.stdenv.cc.cc.lib ] ++ extraLibs);

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        ${installBins}
        ${mkSymlinks}
        ${postInstall}
        runHook postInstall
      '';
    }
    // lib.optionalAttrs (!unpacked) { dontUnpack = true; }
    // lib.optionalAttrs unpacked { sourceRoot = resolvedSourceRoot; });
}
