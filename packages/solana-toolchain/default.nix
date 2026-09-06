{ pkgs, lib, toolbox, toolboxLib }:

# Solana on-chain toolchain: solana-cli + anchor + rustup, with a
# host-independent `cargo-build-sbf` that builds against a pinned,
# offline SBF SDK (nixpkgs SDK scaffolding + toolbox platform-tools).
#
# Consumers just put this on their dev shell — no SBF_SDK_PATH /
# RUSTUP_HOME / --tools-version dance, no platform-tools download, no
# dependence on the host's rustup. `anchor build` works too, since it
# finds the wrapped cargo-build-sbf on PATH.
#
# Unlike the other `*-toolchain` packages this is a hand-written `symlinkJoin`
# rather than `buildToolchain` — the wrapped `cargo-build-sbf` is custom logic
# `buildToolchain` does not model. The version and its toolbox component pin
# still live in `data.json`, so the registry stays data-driven and the docs
# generator (which discovers packages by walking `packages/*/data.json`) sees
# it. See docs/adr/0003.
let
  data = toolboxLib.readData ./data.json;
  version = data.meta.default;

  solanaCli = pkgs.solana-cli;
  anchor = pkgs.anchor;
  rustup = pkgs.rustup;
  platformTools = toolbox.platform-tools.versions.${data.versions.${version}.platform-tools};

  # A complete SBF SDK: nixpkgs' SDK scaffolding with the pinned
  # platform-tools mounted where cargo-build-sbf --skip-tools-install
  # expects them.
  sbfSdk = pkgs.runCommand "solana-sbf-sdk-${version}" { } ''
    cp -R ${solanaCli}/bin/platform-tools-sdk $out
    chmod -R u+w $out
    mkdir -p $out/sbf/dependencies/platform-tools
    cp -R ${platformTools}/. $out/sbf/dependencies/platform-tools/
  '';

  toolchain = pkgs.symlinkJoin {
    name = "solana-toolchain-${version}";
    paths = [ solanaCli anchor rustup ];
    postBuild = ''
      # Replace the raw cargo-build-sbf with the host-independent wrapper.
      rm -f $out/bin/cargo-build-sbf
      substitute ${./cargo-build-sbf.sh} $out/bin/cargo-build-sbf \
        --subst-var-by sbfSdk ${sbfSdk} \
        --subst-var-by rustup ${rustup} \
        --subst-var-by cargoBuildSbf ${solanaCli}/bin/cargo-build-sbf
      chmod +x $out/bin/cargo-build-sbf
      patchShebangs $out/bin/cargo-build-sbf
    '';
    passthru = { inherit sbfSdk platformTools; };
    meta = {
      description = "Solana on-chain toolchain (solana-cli + anchor + offline SBF build)";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
{
  versions = { ${version} = toolchain; };
  default = version;
  # Hand-built rather than produced by buildToolchain (see the header comment),
  # so the stamp every registry entry carries is written out here too. It is a
  # toolchain in the sense the docs render — a meta-package expanded to its
  # component pins — which is what `kind` records.
  toolbox = toolboxLib.mkStamp {
    kind = "toolchain";
    inherit (data) meta;
    components = data.versions;
  };
}
