{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      pkgs.rustPlatform.buildRustPackage {
        pname = "jujutsu";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "jj-vcs";
          repo = "jj";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        nativeBuildInputs = [ pkgs.installShellFiles pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl pkgs.libgit2 pkgs.libssh2 pkgs.zstd ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        cargoBuildFlags = [ "--bin" "jj" ];
        env = {
          ZSTD_SYS_USE_PKG_CONFIG = "1";
          LIBGIT2_NO_VENDOR = "1";
          LIBSSH2_SYS_USE_PKG_CONFIG = "1";
        };
        doCheck = false;

        postInstall = ''
          mkdir -p $out/share/man
          $out/bin/jj util install-man-pages $out/share/man/
          installShellCompletion --cmd jj \
            --bash <(COMPLETE=bash $out/bin/jj) \
            --fish <(COMPLETE=fish $out/bin/jj) \
            --zsh <(COMPLETE=zsh $out/bin/jj)
        '';

        meta = with lib; {
          description = "Git-compatible DVCS that is both simple and powerful";
          homepage = "https://github.com/jj-vcs/jj";
          license = licenses.asl20;
          mainProgram = "jj";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "jj" builders versions;
  default = meta.default;
}
