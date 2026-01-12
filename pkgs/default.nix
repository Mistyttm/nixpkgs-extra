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
    in
    # Detect scope based on common argument patterns
    if args ? "buildPythonApplication" || args ? "buildPythonPackage" then
      prev.python3Packages.callPackage path { }
    else if args ? "mkKdeDerivation" then
      prev.kdePackages.callPackage path { }
    else
      prev.callPackage path { };

  packages = lib.mapAttrs (name: _: callPackage name) packageDirs;
in
packages
