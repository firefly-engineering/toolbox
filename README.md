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

### With home-manager (Claude Code skills)

Skill-bundle packages (e.g. `mattpocock-skills`) are Claude Code plugin directories, wired into the home-manager [`claude-code` module](https://nix-community.github.io/home-manager/options.xhtml) one of two ways:

```nix
# flake input
inputs.toolbox.url = "github:firefly-engineering/toolbox";

# in your home-manager configuration
{ inputs, pkgs, ... }:
let toolbox = inputs.toolbox.packages.${pkgs.system};
in {
  programs.claude-code = {
    enable = true;

    # As a plugin — the bundle's plugin.json drives which skills load:
    plugins = [ toolbox.mattpocock-skills ];

    # …OR as a flat skills directory (mutually exclusive with the plugin above):
    # skills = "${toolbox.mattpocock-skills.skills}";
  };
}
```

Use one route, not both. The `plugins` route needs Claude Code ≥ 2.1.76 (≥ 2.1.157 for persistent personal plugins); the `skills` route has no version floor. Both need a home-manager recent enough to expose `programs.claude-code.skills` / `.plugins`. Bundles are filtered to upstream's `.claude-plugin/plugin.json`, so only the curated skills are installed.

### With home-manager (Claude Code subagents)

`voltagent-subagents` ships VoltAgent's whole subagent catalog without enabling any of it. Pick global agents by name from its flat `agents/` directory, and install its `subagent-catalog` skill to enable others per project:

```nix
{ config, inputs, lib, pkgs, ... }:
let
  subagents = inputs.toolbox.packages.${pkgs.system}.voltagent-subagents;
  globalAgents = [ "code-reviewer" "debugger" ];   # names: `subagent-catalog list`, or catalog.json
in {
  programs.claude-code = {
    enable = true;
    # The plugin's manifest lists the skill only, never the agents.
    plugins = [ subagents ];
    # …OR: skills = "${subagents}/skills";
  };

  # home.file, not programs.claude-code.agents: that option writes a string
  # value as the file's *text*, and a store path read at eval time is IFD.
  home.file = lib.listToAttrs (map (name: {
    name = "${config.programs.claude-code.configDir}/agents/${name}.md";
    value.source = "${subagents}/agents/${name}.md";
  }) globalAgents);
}
```

A misspelt name fails the home-manager build: its `source` does not exist. In a project, ask Claude to enable an agent, or run the skill's script directly: `subagent-catalog enable <name>` copies the packaged definition into `<project>/.claude/agents/`. See [`packages/voltagent-subagents/EGM.md`](packages/voltagent-subagents/EGM.md).

## Platforms

The registry is published for:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`

Some packages cover fewer systems (`bun-baseline` is x86_64-linux only). `x86_64-darwin` is not supported: nixpkgs 26.11 dropped it.

## Adding Packages

See [AGENTS.md](AGENTS.md) for the full guide on adding new packages and versions.

## License

[MIT](LICENSE)
