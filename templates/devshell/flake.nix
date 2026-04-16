{
  description = "Dev environment powered by firefly-engineering/toolbox";

  inputs = {
    nix-pins.url = "github:firefly-engineering/nix-pins";
    nixpkgs.follows = "nix-pins/nixpkgs";
    toolbox.url = "github:firefly-engineering/toolbox";
    toolbox.inputs.nix-pins.follows = "nix-pins";
  };

  outputs =
    { nixpkgs, toolbox, ... }:
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
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          reg = toolbox.registry.${system};

          # Helper: get the default version of a package
          tool = name: reg.${name}.versions.${reg.${name}.default};
        in
        {
          default = pkgs.mkShell {
            packages = [
              # --- Pick your tools below ---

              # Use a toolchain (bundles related tools):
              # (tool "go-toolchain")
              # (tool "rust-toolchain")
              # (tool "python-toolchain")
              # (tool "js-toolchain")

              # Or pick individual tools at their default version:
              (tool "jq")

              # Or pin a specific version:
              # reg.go.versions."1.26.1"
            ];
          };
        }
      );
    };
}
