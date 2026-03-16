{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildToolchain { inherit toolbox pkgs; name = "python-toolchain"; dataPath = ./data.json; }
