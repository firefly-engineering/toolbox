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
          pkgs = nixpkgs.legacyPackages.${system};
          toolboxLib = import ./lib { inherit (pkgs) lib; };
          reg = self.registry.${system};
        in
        builtins.mapAttrs (
          name: entry:
          let
            avail = toolboxLib.availableVersions pkgs.stdenv.hostPlatform entry;
          in
          builtins.listToAttrs (
            map (ver: {
              name = versionToAttr ver;
              value = avail.${ver};
            }) (builtins.attrNames avail)
          )
          // (if avail ? ${entry.default} then {
            default = avail.${entry.default};
          } else {})
        ) reg
      );

      # Flat packages output: nix build .#go-1_25_6, nix build .#beads-default
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          toolboxLib = import ./lib { inherit (pkgs) lib; };
          reg = self.registry.${system};
          lib = nixpkgs.lib;
        in
        builtins.foldl' (
          acc: name:
          let
            entry = reg.${name};
            avail = toolboxLib.availableVersions pkgs.stdenv.hostPlatform entry;
          in
          acc
          // builtins.listToAttrs (
            map (ver: {
              name = "${name}-${versionToAttr ver}";
              value = avail.${ver};
            }) (builtins.attrNames avail)
          )
          // lib.optionalAttrs (avail ? ${entry.default}) {
            # Bare package name points to the default version
            ${name} = avail.${entry.default};
            # Deprecated: use bare package name instead (e.g., .#go not .#go-default)
            "${name}-default" = builtins.trace
              "warning: toolbox: '${name}-default' is deprecated, use '${name}' instead"
              avail.${entry.default};
          }
        ) { } (builtins.attrNames reg)
      );

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
