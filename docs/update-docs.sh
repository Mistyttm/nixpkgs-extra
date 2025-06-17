#!bash

set -euo pipefail

# Build the documentation
nix build .#generate-docs

# Create docs directory if it doesn't exist
mkdir -p docs

# Remove existing README.md if it exists
rm -f docs/README.md

# Copy the generated files to the docs directory
cp -r result/docs/* docs/

echo "Documentation updated successfully in the docs/ directory!"
