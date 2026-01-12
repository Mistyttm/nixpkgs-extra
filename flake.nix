{
  description = "Custom packages and NixOS modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  nixConfig = {
    extra-substituters = [ "https://misty-nixpkgs-extra.cachix.org" ];
    extra-trusted-public-keys = [
      "misty-nixpkgs-extra.cachix.org-1:IaGsrS6TyLFv+wkdYjjWaY9lB2vywnmM7qUZw01kPj0="
    ];
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
          docsGenerator = pkgs.callPackage ./docs/generate.nix { };
        in
        myPackages
        // {
          # Add documentation generator
          generate-docs = docsGenerator {
            packages = myPackages;
          };
        };

      # Export NixOS modules
      nixosModules = import ./modules;

      # Convenience: individual module access
      # nixosModules.some-service = import ./modules/some-service;
      # nixosModules.another-module = import ./modules/another-module;

      formatter.x86_64-linux = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
