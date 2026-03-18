{
  description = "Toolbox: self-contained package registry for turnkey";

  inputs = {
    nix-pins.url = "github:firefly-engineering/nix-pins";
    nixpkgs.follows = "nix-pins/nixpkgs";
    devenv.url = "github:cachix/devenv";
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    teller.url = "github:firefly-engineering/teller";
    teller.inputs.nix-pins.follows = "nix-pins";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      devenv,
      devenv-root,
      teller,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );

      versionToAttr = builtins.replaceStrings [ "." ] [ "_" ];
    in
    {
      # Teller-compatible overlay for registry composition
      overlays.default = teller.lib.mkRegistryOverlay (
        final: prev:
        self.registry.${prev.stdenv.system}
      );

      # Full versioned registry (turnkey-compatible)
      registry = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;
          toolboxLib = import ./lib { inherit lib; };
          packageDirs = lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./packages);
          toolbox = builtins.mapAttrs (
            name: _: import ./packages/${name} { inherit pkgs lib toolbox toolboxLib; }
          ) packageDirs;
        in
        toolbox
      );

      # Nested packages: nix build .#go.1_25_6, nix build .#beads.default
      # Uses legacyPackages because nix flake check requires flat packages output
      legacyPackages = forAllSystems (
        system:
        let
          reg = self.registry.${system};
        in
        builtins.mapAttrs (
          name: entry:
          builtins.listToAttrs (
            map (ver: {
              name = versionToAttr ver;
              value = entry.versions.${ver};
            }) (builtins.attrNames entry.versions)
          )
          // {
            default = entry.versions.${entry.default};
          }
        ) reg
      );

      # Flat packages output: nix build .#go-1_25_6, nix build .#beads-default
      packages = forAllSystems (
        system:
        let
          reg = self.registry.${system};
        in
        builtins.foldl' (
          acc: name:
          let
            entry = reg.${name};
          in
          acc
          // builtins.listToAttrs (
            map (ver: {
              name = "${name}-${versionToAttr ver}";
              value = entry.versions.${ver};
            }) (builtins.attrNames entry.versions)
          )
          // {
            "${name}-default" = entry.versions.${entry.default};
          }
        ) { } (builtins.attrNames reg)
      );

      # Development shell via devenv (activated by direnv)
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          reg = self.registry.${system};
          beadwork = reg.beadwork.versions.${reg.beadwork.default};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                devenv.root =
                  let
                    devenvRootFileContent = builtins.readFile inputs.devenv-root.outPath;
                  in
                  pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

                packages = [ beadwork ];

                languages.nix.enable = true;
                languages.python.enable = true;
              }
            ];
          };
        }
      );
    };
}
