cache := "firefly-toolbox"
system := `nix eval --impure --raw --expr 'builtins.currentSystem'`

# List available recipes
default:
    @just --list

# Build all packages for the given system
build-packages system=system:
    nix build --no-link --print-out-paths --impure --expr \
        'builtins.attrValues (builtins.getFlake (toString ./.)).packages.{{ system }}'

# Build the dev shell's build dependencies
build-devshell system=system:
    @[ -f .devenv-root ] || printf %s "$PWD" > .devenv-root
    nix build --no-link --print-out-paths --impure \
        --override-input devenv-root "file+file://$PWD/.devenv-root" \
        .#devShells.{{ system }}.default.inputDerivation

# Push all packages to cachix
push-packages system=system:
    just build-packages {{ system }} | cachix push {{ cache }}

# Push dev shell build dependencies to cachix
push-devshell system=system:
    just build-devshell {{ system }} | cachix push {{ cache }}

# Push packages and dev shells to cachix
push system=system: (push-packages system) (push-devshell system)
