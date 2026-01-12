#!/usr/bin/env bash
set -euo pipefail

# Query NuGet API for latest version
NUGET_PACKAGE="vrchat.vpm.cli"
LATEST_VERSION=$(curl -s "https://api.nuget.org/v3-flatcontainer/${NUGET_PACKAGE}/index.json" | jq -r '.versions[-1]')

# Get current version from package.nix
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$SCRIPT_DIR/package.nix"
CURRENT_VERSION=$(grep 'version = ' "$PACKAGE_FILE" | sed 's/.*version = "\([^"]*\)".*/\1/')

if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
    echo "vpm is up to date at version $CURRENT_VERSION"
    exit 0
fi

echo "Updating vpm from $CURRENT_VERSION to $LATEST_VERSION"

# Calculate new hash using nix-prefetch
DOWNLOAD_URL="https://api.nuget.org/v3-flatcontainer/${NUGET_PACKAGE}/${LATEST_VERSION}/${NUGET_PACKAGE}.${LATEST_VERSION}.nupkg"
NEW_HASH=$(nix-prefetch-url "$DOWNLOAD_URL" 2>/dev/null | xargs nix hash to-sri --type sha256)

# Update version
sed -i "s/version = \"$CURRENT_VERSION\"/version = \"$LATEST_VERSION\"/" "$PACKAGE_FILE"

# Update hash
sed -i "s|nugetSha256 = \"[^\"]*\"|nugetSha256 = \"$NEW_HASH\"|" "$PACKAGE_FILE"

echo "Updated vpm to version $LATEST_VERSION with hash $NEW_HASH"
