final: prev:
let
  lib = prev.lib;
  entries = builtins.readDir ./.;
  dirs = lib.filterAttrs (name: type: type == "directory") entries;
  
  packageDirs = lib.filterAttrs (name: type:
    type == "directory" && 
    builtins.pathExists (./${name} + "/default.nix")
  ) dirs;
  
  packages = lib.mapAttrs (name: _:
    prev.callPackage (./${name}) { }
  ) packageDirs;
in
packages