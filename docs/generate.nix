{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) lib;
  nixpkgsExtraFlake = builtins.getFlake (toString ./..);
  system = "x86_64-linux";

  # Get all packages
  allPackages = nixpkgsExtraFlake.packages.${system};

  # Generate package documentation
  packagesDoc = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: pkg: ''
    ### ${name}

    ${pkg.meta.description or "No description available."}

    - **License**: ${pkg.meta.license.shortName or "Unknown"}
    - **Homepage**: [${pkg.meta.homepage or "N/A"}](${pkg.meta.homepage or "#"})
    - **Maintainers**: ${toString (builtins.map (m: m.name) (pkg.meta.maintainers or []))}
  '') allPackages);

  # Generate modules documentation
  # For each NixOS module, we'd need to extract options
  # This is a simplified version - for more complete docs, you'd use nixosOptionsDoc

  # Final output
  markdown = ''
    # Nixpkgs-Extra Documentation

    *Automatically generated on ${builtins.substring 0 10 (builtins.toString builtins.currentTime)}*

    ## Available Packages

    ${packagesDoc}

    ## Available NixOS Modules

    *Coming soon*
  '';

  # Write to file
  docsFile = pkgs.writeTextFile {
    name = "nixpkgs-extra-docs";
    text = markdown;
    destination = "/docs/PACKAGES.md";
  };

in pkgs.runCommand "nixpkgs-extra-docs" {} ''
  mkdir -p $out
  cp -r ${docsFile}/docs $out/
''
