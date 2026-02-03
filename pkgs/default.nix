final: prev:
let
  lib = prev.lib;
  entries = builtins.readDir ./.;

  # Find all directories containing a package.nix
  packageDirs = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists (./${name}/package.nix)
  ) entries;

  # Helper to call a package with the right scope
  callPackage =
    name:
    let
      path = ./${name}/package.nix;
      # Peek at the function arguments to detect the right scope
      fn = import path;
      args = lib.functionArgs fn;
      # Special overrides for specific packages
      extraArgs = if name == "claude-vault" then { ollama = prev.ollama; } else { };
    in
    # Detect scope based on common argument patterns
    if args ? "buildPythonApplication" || args ? "buildPythonPackage" then
      prev.python3Packages.callPackage path extraArgs
    else if args ? "mkKdeDerivation" then
      prev.kdePackages.callPackage path extraArgs
    else
      prev.callPackage path extraArgs;

  packages = lib.mapAttrs (name: _: callPackage name) packageDirs;
in
packages
