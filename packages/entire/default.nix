{ pkgs, lib, toolbox, toolboxLib }:

let
  # goreleaser archives: binaries + completions at the archive root (no wrapping
  # directory), so sourceRoot is ".". Each tarball also ships git-remote-entire,
  # the git remote helper the CLI drives, so both binaries are installed.
  assetSuffix = {
    "x86_64-linux" = "linux_amd64.tar.gz";
    "aarch64-linux" = "linux_arm64.tar.gz";
    "x86_64-darwin" = "darwin_amd64.tar.gz";
    "aarch64-darwin" = "darwin_arm64.tar.gz";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "entire ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "entire";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/entireio/cli/releases/download/v${version}/entire_${assetSuffix}";
          hash = platformData.sha256;
        };

        sourceRoot = ".";

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = [ pkgs.installShellFiles ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -m755 entire $out/bin/entire
          install -m755 git-remote-entire $out/bin/git-remote-entire

          installShellCompletion --cmd entire \
            --bash completions/entire.bash \
            --fish completions/entire.fish \
            --zsh completions/entire.zsh

          runHook postInstall
        '';

        meta = with lib; {
          description = "Entire CLI: capture AI agent sessions as a searchable record alongside your Git commits";
          homepage = "https://entire.io";
          license = licenses.mit;
          mainProgram = "entire";
          platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        };
      };
  };
in
toolboxLib.buildPackage { name = "entire"; dataPath = ./data.json; inherit builders; }
