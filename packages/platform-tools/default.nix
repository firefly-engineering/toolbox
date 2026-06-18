{ pkgs, lib, toolbox, toolboxLib }:

# Solana "platform-tools" — the sbpf rustc + LLVM toolchain cargo-build-sbf
# needs to build on-chain programs. Distributed as prebuilt per-platform
# tarballs (rust/, llvm/, version.md). Pinning it here (rather than letting
# cargo-build-sbf download it at build time) is what makes the SBF build
# reproducible / offline.
let
  inherit (toolboxLib.readData ./data.json) meta versions;

  asset = {
    "x86_64-linux" = "platform-tools-linux-x86_64.tar.bz2";
    "aarch64-linux" = "platform-tools-linux-aarch64.tar.bz2";
    "x86_64-darwin" = "platform-tools-osx-x86_64.tar.bz2";
    "aarch64-darwin" = "platform-tools-osx-aarch64.tar.bz2";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "platform-tools: unsupported system ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "platform-tools ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "platform-tools";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/anza-xyz/platform-tools/releases/download/${version}/${asset}";
          hash = platformData.sha256;
        };

        # Tarball holds rust/ llvm/ version.md at the top level.
        sourceRoot = ".";
        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;
        # The toolchain ships a few prebuilt-tarball warts: a dangling
        # lldb-argdumper symlink (lldb debug helper, irrelevant to builds).
        dontCheckForBrokenSymlinks = true;

        # macOS binaries run unpatched. On Linux the prebuilt ELF binaries
        # need their interpreter/rpaths fixed; ignore-missing keeps the
        # large toolchain from hard-failing on optional deps.
        # NOTE: the Linux path is not yet verified on this hardware.
        nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];
        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
          pkgs.libxml2
          pkgs.ncurses
        ];
        autoPatchelfIgnoreMissingDeps = pkgs.stdenv.hostPlatform.isLinux;

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -R rust llvm version.md $out/
          runHook postInstall
        '';

        meta = {
          description = "Solana platform-tools (sbpf rustc + LLVM) for cargo-build-sbf";
          homepage = "https://github.com/anza-xyz/platform-tools";
          license = with lib.licenses; [ asl20 mit ];
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ];
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "platform-tools" builders versions;
  default = meta.default;
}
