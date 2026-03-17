{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildToolchain { inherit toolbox pkgs; name = "mdbook-toolchain"; dataPath = ./data.json; }
