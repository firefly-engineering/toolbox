{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    # treefmt comes from toolbox (pinned, prebuilt). nixfmt is a Haskell
    # program with no toolbox builder, so it is taken from the pinned nixpkgs.
    default = version: versionData:
      let
        treefmt = toolbox.treefmt.versions.${versionData.treefmt};
        nixfmt = pkgs.nixfmt;

        # Mirrors nixpkgs' nixfmt-tree treefmt config: nixfmt for *.nix, and a
        # quieter log level for files treefmt won't format.
        configFile = pkgs.writeText "treefmt.toml" ''
          on-unmatched = "info"

          [formatter.nixfmt]
          command = "nixfmt"
          includes = ["*.nix"]
        '';
      in
      pkgs.symlinkJoin {
        name = "nixfmt-tree-${version}";
        paths = [ treefmt ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/treefmt" \
            --prefix PATH : "${lib.makeBinPath [ nixfmt ]}" \
            --add-flags "--config-file ${configFile}"
        '';

        meta = with lib; {
          description = "Zero-setup Nix formatter using treefmt and nixfmt";
          homepage = "https://github.com/NixOS/nixfmt";
          license = licenses.mit;
          mainProgram = "treefmt";
          platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        };
      };
  };
in
toolboxLib.buildPackage { name = "nixfmt-tree"; dataPath = ./data.json; inherit builders; }
