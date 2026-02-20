{
  description = "Toolbox: self-contained package registry for turnkey";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
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
      # Full versioned registry (turnkey-compatible)
      registry = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;
          packageDirs = lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./packages);
          toolbox = builtins.mapAttrs (
            name: _: import ./packages/${name} { inherit pkgs lib toolbox; }
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
    };
}
