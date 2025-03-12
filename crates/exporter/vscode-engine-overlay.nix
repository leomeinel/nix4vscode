{ lib }:

final: prev: {
  vscodeExtensionsForEngine =
    engineVersion:
    let
      # Read extensions.toml file
      extensionsToml = builtins.fromTOML (builtins.readFile ./extensions.toml);
      extensions = extensionsToml.extension or [ ];

      # Get current system and architecture information
      currentSystem = builtins.currentSystem;

      # Map Nix system identifiers to VSCode platform identifiers
      platformMap = {
        "x86_64-linux" = "linux-x64";
        "aarch64-linux" = "linux-arm64";
        "armv7l-linux" = "linux-armhf";
        "x86_64-darwin" = "darwin-x64";
        "aarch64-darwin" = "darwin-arm64";
      };

      # Get the VSCode platform identifier for the current system
      currentPlatform = platformMap.${currentSystem} or null;

      # Check if extension platform is compatible with the current system
      # Web platform is considered universal and can run on any system
      matchesPlatform =
        ext:
        let
          extPlatform = ext.platform or "";
        in
        extPlatform == "web"
        || (
          currentPlatform != null
          && (
            extPlatform == currentPlatform
            ||
              # For alpine systems, if there's no specific alpine version, we can use the regular linux version
              (
                lib.strings.hasPrefix "alpine-" extPlatform
                && lib.strings.hasPrefix "linux-" currentPlatform
                &&
                  lib.strings.removePrefix "alpine-" extPlatform == lib.strings.removePrefix "linux-" currentPlatform
              )
          )
        );

      # Check if the version matches
      # We simplify the handling here, only checking prefix matching, e.g., "^1.85.0" matches "1.85.x"
      matchesEngine =
        ext:
        let
          extEngine = ext.engine or "";
          # Remove prefix symbols (such as ^, ~, etc.)
          cleanExtEngine =
            builtins.replaceStrings
              [
                "^"
                "~"
                "="
                ">="
                "<="
                ">"
                "<"
              ]
              [
                ""
                ""
                ""
                ""
                ""
                ""
                ""
              ]
              extEngine;
          # Get the major version number parts for comparison
          extMajorMinor = lib.strings.concatStringsSep "." (
            lib.lists.take 2 (lib.strings.splitString "." cleanExtEngine)
          );
          versionMajorMinor = lib.strings.concatStringsSep "." (
            lib.lists.take 2 (lib.strings.splitString "." engineVersion)
          );
        in
        extMajorMinor == versionMajorMinor;

      # Filter extensions matching the specified engine version and current platform
      filteredByEngine = builtins.filter matchesEngine extensions;
      filteredExtensions = builtins.filter matchesPlatform filteredByEngine;
    in
    filteredExtensions;

  # Add a function that allows specifying a platform instead of using the current system
  vscodeExtensionsForEnginePlatform =
    engineVersion: platform:
    let
      # Read extensions.toml file
      extensionsToml = builtins.fromTOML (builtins.readFile ./extensions.toml);
      extensions = extensionsToml.extension or [ ];

      # Check if extension platform is compatible with the specified platform
      matchesPlatform =
        ext:
        let
          extPlatform = ext.platform or "";
        in
        extPlatform == "web" || extPlatform == platform;

      # Check if the version matches
      matchesEngine =
        ext:
        let
          extEngine = ext.engine or "";
          # Remove prefix symbols (such as ^, ~, etc.)
          cleanExtEngine =
            builtins.replaceStrings
              [
                "^"
                "~"
                "="
                ">="
                "<="
                ">"
                "<"
              ]
              [
                ""
                ""
                ""
                ""
                ""
                ""
                ""
              ]
              extEngine;
          # Get the major version number parts for comparison
          extMajorMinor = lib.strings.concatStringsSep "." (
            lib.lists.take 2 (lib.strings.splitString "." cleanExtEngine)
          );
          versionMajorMinor = lib.strings.concatStringsSep "." (
            lib.lists.take 2 (lib.strings.splitString "." engineVersion)
          );
        in
        extMajorMinor == versionMajorMinor;

      # Filter extensions matching the specified engine version and platform
      filteredByEngine = builtins.filter matchesEngine extensions;
      filteredExtensions = builtins.filter matchesPlatform filteredByEngine;
    in
    filteredExtensions;
}
