{ pkgs, lib, toolbox, toolboxLib }:

let
  # The release tarball is a flat `pulumi/` directory: the CLI plus the language
  # hosts it shells out to. The CLI resolves a language host by looking for
  # `pulumi-language-<lang>` next to itself (and on PATH), so they all have to
  # land in $out/bin together.
  binaries = [
    "pulumi"
    "pulumi-language-bun"
    "pulumi-language-dotnet"
    "pulumi-language-go"
    "pulumi-language-java"
    "pulumi-language-nodejs"
    "pulumi-language-pcl"
    "pulumi-language-python"
    "pulumi-language-python-exec"
    "pulumi-language-yaml"
    "pulumi-resource-pulumi-nodejs"
    "pulumi-resource-pulumi-python"
    "pulumi-watch"
  ];

  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs binaries;
    pname = "pulumi";
    platforms = {
      "x86_64-linux" = "linux-x64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-x64";
      "aarch64-darwin" = "darwin-arm64";
    };
    url =
      { version, platform }:
      "https://github.com/pulumi/pulumi/releases/download/v${version}/pulumi-v${version}-${platform}.tar.gz";
    sourceRoot = "pulumi";
    meta = {
      description = "Infrastructure as code in any programming language";
      homepage = "https://www.pulumi.com";
      license = lib.licenses.asl20;
      mainProgram = "pulumi";
    };
  };
in
toolboxLib.buildPackage {
  name = "pulumi";
  dataPath = ./data.json;
  inherit builders;
}
