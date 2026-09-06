{
  description = "Toolbox: self-contained package registry for turnkey";

  nixConfig = {
    extra-substituters = [ "https://firefly-toolbox.cachix.org" ];
    extra-trusted-public-keys = [ "firefly-toolbox.cachix.org-1:4RgCoc0+CS7QhRarG109VmWlnlYi+rQ5JYrCsRP5aK8=" ];
  };

  inputs = {
    nix-pins.url = "github:firefly-engineering/nix-pins";
    nixpkgs.follows = "nix-pins/nixpkgs";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.flake-compat.follows = "nix-pins/flake-compat";
    devenv.inputs.flake-parts.follows = "nix-pins/flake-parts";
    devenv.inputs.nixpkgs.follows = "nix-pins/nixpkgs";
    devenv.inputs.crate2nix.follows = "";
    devenv.inputs.ghostty.follows = "";
    devenv.inputs.nix.follows = "";
    devenv.inputs.nixd.follows = "";

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
      # x86_64-darwin is absent deliberately: nixpkgs 26.11 dropped it, so
      # `nixpkgs.legacyPackages.x86_64-darwin` throws on import and every
      # output for that system was already broken. Advertising it only made
      # the breakage silent.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
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

      # Both flake package outputs come from one place in lib, so the naming
      # contract (version dots to underscores, bare name means the default
      # version) has a single owner.
      outputsFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          toolboxLib = import ./lib { inherit (pkgs) lib; };
        in
        toolboxLib.registryOutputs {
          inherit pkgs;
          registry = self.registry.${system};
        };
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

      # Both package outputs come from one place in lib, so the naming contract
      # (version dots to underscores, bare name means default) has a single
      # owner. legacyPackages rather than packages for the nested one because
      # `nix flake check` requires the packages output to be flat.
      #
      #   nix build .#go.1_25_6   (nested)
      #   nix build .#go-1_25_6   (flat)
      #   nix build .#go          (flat, the default version)
      legacyPackages = forAllSystems (system: (outputsFor system).nested);

      packages = forAllSystems (system: (outputsFor system).flat);

      # Eval-time registry invariants, on every system the flake advertises.
      # Building all packages only ever gated x86_64-linux; this gates the
      # other three too, in seconds rather than an hour.
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          toolboxLib = import ./lib { inherit (pkgs) lib; };
        in
        {
          registry = toolboxLib.checkRegistry {
            inherit pkgs;
            registry = self.registry.${system};
            packagesDir = ./packages;
          };
        }
      );

      # Flake templates for downstream consumers
      templates = {
        default = {
          path = ./templates/devshell;
          description = "Dev shell with toolbox packages";
        };
        devshell = {
          path = ./templates/devshell;
          description = "Dev shell with toolbox packages";
        };
        go = {
          path = ./templates/go;
          description = "Go project with toolbox Go toolchain";
        };
        rust = {
          path = ./templates/rust;
          description = "Rust project with toolbox Rust toolchain";
        };
      };

      # Development shell via devenv (activated by direnv)
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          reg = self.registry.${system};
          beadwork = reg.beadwork.versions.${reg.beadwork.default};
          vcs-toolchain = reg.vcs-toolchain.versions.${reg.vcs-toolchain.default};
          just = reg.just.versions.${reg.just.default};
          nix = reg.nix.versions.${reg.nix.default};
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

                packages = [ beadwork vcs-toolchain just nix ];

                languages.nix.enable = true;
                languages.python.enable = true;
              }
            ];
          };
        }
      );
    };
}
