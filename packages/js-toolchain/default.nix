{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildToolchain { inherit toolbox pkgs; name = "js-toolchain"; dataPath = ./data.json; }
