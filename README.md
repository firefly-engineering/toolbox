# Toolbox

A self-contained, data-driven package registry for [turnkey](https://github.com/firefly-engineering/turnkey). Version metadata lives in JSON data files — Nix code reads this data to build derivations automatically. Adding a new version means adding a JSON entry, not editing Nix code.

## Packages

Toolbox provides versioned, reproducible builds of curated development tools across Linux (x64/arm64) and macOS (x64/arm64), plus toolchain meta-packages that bundle related tools together.

Browse the full package catalog: **[firefly-engineering.github.io/toolbox](https://firefly-engineering.github.io/toolbox)**

## Usage

### Standalone

```bash
# Build a specific version
nix build .#go.1_26_0

# Build the default version
nix build .#beads.default

# Build a toolchain meta-package
nix build .#rust-toolchain.default

# Run a tool directly
nix run .#jq.default -- --version
```

### With Turnkey

```nix
# In turnkey's flake.nix:
inputs.toolbox.url = "github:firefly-engineering/toolbox";

# In registryExtensions:
registryExtensions = {
  go = inputs.toolbox.registry.${system}.go;
  beads = inputs.toolbox.registry.${system}.beads;
};
```

## Platforms

All packages target:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Adding Packages

See [AGENTS.md](AGENTS.md) for the full guide on adding new packages and versions.

## License

[MIT](LICENSE)
