{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildToolchain { inherit toolbox pkgs; name = "go-toolchain"; dataPath = ./data.json; }
