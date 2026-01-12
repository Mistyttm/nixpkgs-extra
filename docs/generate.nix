{
  pkgs,
  lib ? pkgs.lib,
}:

let
  # Instead of getting packages from the flake directly, pass them as an argument
  generateDocs =
    {
      packages ? { },
    }:
    let
      # Generate package documentation
      packagesDoc = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: pkg:
          if name != "generate-docs" then
            ''
              ### ${name}

              ${pkg.meta.description or "No description available."}

              - **License**: ${pkg.meta.license.shortName or "Unknown"}
              - **Homepage**: [${pkg.meta.homepage or "N/A"}](${pkg.meta.homepage or "#"})
            ''
          else
            ""
        ) packages
      );

      # Final output without date (will be added at build time)
      markdown = ''
        # Nixpkgs-Extra Documentation

        *Automatically generated on DATE_PLACEHOLDER*

        ## Available Packages

        ${packagesDoc}
      '';

      # Write to file
      docsFile = pkgs.writeTextFile {
        name = "nixpkgs-extra-docs";
        text = markdown;
        destination = "/docs/README.md";
      };
    in
    pkgs.runCommand "nixpkgs-extra-docs" { } ''
      mkdir -p $out/docs
      DATE=$(date +%Y-%m-%d)
      cat ${docsFile}/docs/README.md | sed "s/DATE_PLACEHOLDER/$DATE/g" > $out/docs/README.md
    '';
in
# Return the function so it can be called with appropriate packages
generateDocs
