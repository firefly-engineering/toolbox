{ pkgs, lib, toolbox, toolboxLib }:

let
  prebuilt = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "buck2";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-linux" = "aarch64-unknown-linux-gnu";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/facebook/buck2/releases/download/${version}/buck2-${platform}.zst";
    binaries = [ "buck2" ];
    meta = with lib; {
      description = "Buck2: fast, hermetic build system from Meta";
      homepage = "https://buck2.build/";
      license = with lib.licenses; [ asl20 mit ];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };

  # The release tag names a date, not a build. `rev` is the buck2 commit the
  # tag points at, so a consumer pinning a source revision (turnkey's pinned
  # buck2 release) can check the binary against it, as it does the prelude's
  # `preludeRev`. Passthru only: the derivation itself is unchanged.
  builders.default = version: versionData:
    (prebuilt version versionData).overrideAttrs (old: {
      passthru = (old.passthru or { }) // {
        rev = versionData.rev or (throw "buck2 ${version} has no rev in data.json");
      };
    });
in
toolboxLib.buildPackage { name = "buck2"; dataPath = ./data.json; inherit builders; }
