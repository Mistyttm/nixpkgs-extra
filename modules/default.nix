{
  # Default: all modules imported together
  default = { ... }: {
    imports = [
      ./tdarr.nix
      # ./steam-presence.nix
    ];
  };

  # Individual module access
  tdarr = import ./tdarr.nix;
  # steam-presence = import ./steam-presence.nix;
}
