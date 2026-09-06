{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "jujutsu";
    owner = "jj-vcs";
    repo = "jj";
    extraArgs = {
      nativeBuildInputs = [ pkgs.installShellFiles pkgs.pkg-config ];
      buildInputs = [ pkgs.openssl pkgs.libgit2 pkgs.libssh2 pkgs.zstd ];

      cargoBuildFlags = [ "--bin" "jj" ];
      env = {
        ZSTD_SYS_USE_PKG_CONFIG = "1";
        LIBGIT2_NO_VENDOR = "1";
        LIBSSH2_SYS_USE_PKG_CONFIG = "1";
      };

      postInstall = ''
        mkdir -p $out/share/man
        $out/bin/jj util install-man-pages $out/share/man/
        installShellCompletion --cmd jj \
          --bash <(COMPLETE=bash $out/bin/jj) \
          --fish <(COMPLETE=fish $out/bin/jj) \
          --zsh <(COMPLETE=zsh $out/bin/jj)
      '';
    };
    meta = with lib; {
      description = "Git-compatible DVCS that is both simple and powerful";
      homepage = "https://github.com/jj-vcs/jj";
      license = licenses.asl20;
      mainProgram = "jj";
    };
  };
in
toolboxLib.buildPackage { name = "jj"; dataPath = ./data.json; inherit builders; }
