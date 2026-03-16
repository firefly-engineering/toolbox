{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildToolchain { inherit toolbox pkgs; name = "solidity-toolchain"; dataPath = ./data.json; }
