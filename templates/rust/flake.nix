{
  description = "Rust project with firefly-engineering/toolbox";

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

          # Rust toolchain: rust + rust-analyzer + cargo-edit
          rustToolchain = reg.rust-toolchain.versions.${reg.rust-toolchain.default};
          rust = reg.rust.versions.${reg.rust.default};
        in
        {
          default = pkgs.mkShell {
            packages = [
              rustToolchain
            ];

            env = {
              RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust/library";
            };
          };
        }
      );
    };
}
