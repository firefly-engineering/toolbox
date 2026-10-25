{ pkgs, lib, toolbox, toolboxLib }:

let
  # Map Nix system names to Rust target triples
  targetTriple = {
    "x86_64-linux"  = "x86_64-unknown-linux-gnu";
    "aarch64-linux"  = "aarch64-unknown-linux-gnu";
    "x86_64-darwin"  = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  # The platform-independent rust-src component, installed on its own:
  # $out/lib/rustlib/src/rust/library.
  mkRustSrc = version: srcData:
    pkgs.stdenv.mkDerivation {
      pname = "rust-src";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://static.rust-lang.org/dist/rust-src-${version}.tar.xz";
        hash = srcData.sha256;
      };

      dontConfigure = true;
      dontBuild = true;
      # Sources only: nothing to strip or patch.
      dontFixup = true;

      installPhase = ''
        runHook preInstall
        bash install.sh --prefix=$out --components=rust-src --disable-ldconfig
        rm -rf $out/lib/rustlib/{manifest-*,install.log,rust-installer-version,components,uninstall.sh}
        runHook postInstall
      '';
    };

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "Rust ${version} has no binary for ${system}");
      in
      # Asserted rather than read lazily from passthru, so a missing rustSrc
      # fails `nix flake check` (which forces drvPath, never passthru).
      assert lib.assertMsg (versionData ? rustSrc.sha256)
        "Rust ${version} has no rustSrc.sha256 in data.json";
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
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          bash install.sh \
            --prefix=$out \
            --components=rustc,cargo,rust-std-${targetTriple},clippy-preview,rustfmt-preview \
            --disable-ldconfig

          # Remove installation manifest (not needed in Nix store)
          rm -rf $out/lib/rustlib/{manifest-*,install.log,rust-installer-version,components,uninstall.sh}

          runHook postInstall
        '';

        passthru = {
          targetPlatforms = lib.platforms.all;
          badTargetPlatforms = [ ];
          # Std sources for rust-analyzer (RUST_SRC_PATH). Passthru, not an
          # installed component, so this derivation and every Rust package
          # built with it stay unchanged.
          rustSrc = mkRustSrc version versionData.rustSrc;
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
toolboxLib.buildPackage { name = "rust"; dataPath = ./data.json; inherit builders; }
