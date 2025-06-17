{
  # Auto-import all modules from subdirectories
  imports =
    let
      entries = builtins.readDir ./.;
      dirs = builtins.filter (
        name:
        (builtins.readFileType (./${name}) == "directory")
        && (builtins.pathExists (./${name} + "/default.nix"))
      ) (builtins.attrNames entries);
    in
    map (dir: ./${dir}) dirs;
}
