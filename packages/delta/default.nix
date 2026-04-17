{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  system = pkgs.stdenv.hostPlatform.system;

  targetTriple = {
    "x86_64-linux" = "x86_64-unknown-linux-gnu";
    "aarch64-linux" = "aarch64-unknown-linux-gnu";
    "aarch64-darwin" = "aarch64-apple-darwin";
  };

  mkMeta = {
    description = "A syntax-highlighting pager for git, diff, and grep output";
    homepage = "https://github.com/dandavison/delta";
    license = lib.licenses.mit;
    mainProgram = "delta";
  };

  # Prebuilt binary for platforms with releases
  mkPrebuilt = version: versionData:
    let
      triple = targetTriple.${system};
      platformData = versionData.${system};
    in
    pkgs.stdenv.mkDerivation {
      pname = "delta";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-${triple}.tar.gz";
        hash = platformData.sha256;
      };

      sourceRoot = "delta-${version}-${triple}";

      dontConfigure = true;
      dontBuild = true;
      dontStrip = true;

      nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.autoPatchelfHook
      ];

      buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.stdenv.cc.cc.lib
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        install -m755 delta $out/bin/delta
        runHook postInstall
      '';

      meta = mkMeta;
    };

  # Build from source for platforms without prebuilt binaries
  mkFromSource = version: versionData:
    let
      rust = toolbox.rust.versions.${versionData.rust};
      rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
    in
    rustPlatform.buildRustPackage {
      pname = "delta";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "dandavison";
        repo = "delta";
        rev = version;
        hash = versionData.srcHash;
      };

      cargoHash = versionData.cargoHash;
      doCheck = false;

      meta = mkMeta;
    };

  builders = {
    default = version: versionData:
      if versionData ? ${system} then
        mkPrebuilt version versionData
      else
        mkFromSource version versionData;
  };
in
{
  versions = toolboxLib.buildVersions "delta" builders versions;
  default = meta.default;
}
