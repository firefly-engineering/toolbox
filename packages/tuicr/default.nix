{ pkgs, lib, toolbox, toolboxLib }:

let
  meta = with lib; {
    description = "A code review TUI with vim keybindings";
    homepage = "https://github.com/agavra/tuicr";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "tuicr";
  };

  # Built from the tagged source tree rather than the release tarball (which
  # ships only the binary), so this pin is the *same* source `tuicr-skills`
  # bundles its skill from — the two cannot drift apart.
  builders.source = version: versionData:
    let
      rust = toolbox.rust.versions.${versionData.rust};
      rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
    in
    rustPlatform.buildRustPackage {
      pname = "tuicr";
      inherit version;
      src = pkgs.fetchFromGitHub {
        inherit (versionData) owner repo rev;
        hash = versionData.sha256;
      };
      cargoHash = versionData.cargoHash;

      # git2 is built with default-features = false and libgit2-sys vendors its
      # own libgit2, so there is nothing to find via pkg-config on Darwin. The
      # Linux inputs are for arboard's X11/Wayland clipboard backends.
      nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pkg-config ];
      buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.libxkbcommon
        pkgs.wayland
        pkgs.xorg.libxcb
      ];

      doCheck = false;

      inherit meta;
    };

  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "tuicr";
    platforms = {
      "x86_64-linux"   = "x86_64-unknown-linux-gnu";
      "aarch64-linux"  = "aarch64-unknown-linux-gnu";
      "x86_64-darwin"  = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/agavra/tuicr/releases/download/v${version}/tuicr-${version}-${platform}.tar.gz";
    sourceRoot = ".";
    binaries = [ "tuicr" ];
    inherit meta;
  };
in
toolboxLib.buildPackage { name = "tuicr"; dataPath = ./data.json; inherit builders; }
