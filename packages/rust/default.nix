{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  # Map Nix system names to Rust target triples
  targetTriple = {
    "x86_64-linux"  = "x86_64-unknown-linux-gnu";
    "aarch64-linux"  = "aarch64-unknown-linux-gnu";
    "x86_64-darwin"  = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "Rust ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "rust";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://static.rust-lang.org/dist/rust-${version}-${targetTriple}.tar.xz";
          hash = platformData.sha256;
        };

        nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib  # libgcc_s.so.1
          pkgs.zlib              # libz.so.1
        ];

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          bash install.sh \
            --prefix=$out \
            --components=rustc,cargo,rust-std-${targetTriple} \
            --disable-ldconfig

          # Remove installation manifest (not needed in Nix store)
          rm -rf $out/lib/rustlib/{manifest-*,install.log,rust-installer-version,components,uninstall.sh}

          runHook postInstall
        '';

        passthru = {
          targetPlatforms = lib.platforms.all;
          badTargetPlatforms = [ ];
        };

        meta = {
          description = "Rust toolchain (pre-built binary from static.rust-lang.org)";
          homepage = "https://www.rust-lang.org/";
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
  versions = toolboxLib.buildVersions "rust" builders versions;
  default = meta.default;
}
