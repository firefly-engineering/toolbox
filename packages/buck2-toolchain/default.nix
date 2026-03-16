{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildToolchain { inherit toolbox pkgs; name = "buck2-toolchain"; dataPath = ./data.json; }
