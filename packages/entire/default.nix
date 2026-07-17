{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "entire";
    platforms = {
      "x86_64-linux" = "linux_amd64.tar.gz";
      "aarch64-linux" = "linux_arm64.tar.gz";
      "x86_64-darwin" = "darwin_amd64.tar.gz";
      "aarch64-darwin" = "darwin_arm64.tar.gz";
    };
    url = { version, platform }:
      "https://github.com/entireio/cli/releases/download/v${version}/entire_${platform}";
    binaries = [ "entire" "git-remote-entire" ];
    sourceRoot = ".";
    postInstall = ''
      installShellCompletion --cmd entire \
        --bash completions/entire.bash \
        --fish completions/entire.fish \
        --zsh completions/entire.zsh
    '';
    meta = with lib; {
      description = "Entire CLI: capture AI agent sessions as a searchable record alongside your Git commits";
      homepage = "https://entire.io";
      license = licenses.mit;
      mainProgram = "entire";
      platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    };
  };
in
toolboxLib.buildPackage { name = "entire"; dataPath = ./data.json; inherit builders; }
