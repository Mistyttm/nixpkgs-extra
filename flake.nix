{
  description = "Custom packages and NixOS modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      # Package overlay
      overlays.default = import ./pkgs;

      # Export packages
      packages.${system} =
        let
          myOverlay = self.overlays.default;
          myPackages = myOverlay pkgs pkgs;
        in
        myPackages;

      # Export NixOS modules
      nixosModules = import ./modules;

      # Convenience: individual module access
      # nixosModules.some-service = import ./modules/some-service;
      # nixosModules.another-module = import ./modules/another-module;

      formatter.x86_64-linux = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
