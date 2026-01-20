#!/usr/bin/env bash

VERSION="2.58.02"

fetch_and_convert() {
    local url=$1
    local hash=$(nix-prefetch-url "$url" 2>/dev/null)
    nix hash to-sri --type sha256 "$hash"
}

echo "hashes = {"

echo "  linux_x64 = {"
echo "    server = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/linux_x64/Tdarr_Server.zip)\";"
echo "    node = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/linux_x64/Tdarr_Node.zip)\";"
echo "  };"

echo "  linux_arm64 = {"
echo "    server = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/linux_arm64/Tdarr_Server.zip)\";"
echo "    node = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/linux_arm64/Tdarr_Node.zip)\";"
echo "  };"

echo "  darwin_x64 = {"
echo "    server = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/darwin_x64/Tdarr_Server.zip)\";"
echo "    node = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/darwin_x64/Tdarr_Node.zip)\";"
echo "  };"

echo "  darwin_arm64 = {"
echo "    server = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/darwin_arm64/Tdarr_Server.zip)\";"
echo "    node = \"$(fetch_and_convert https://storage.tdarr.io/versions/$VERSION/darwin_arm64/Tdarr_Node.zip)\";"
echo "  };"

echo "};"
