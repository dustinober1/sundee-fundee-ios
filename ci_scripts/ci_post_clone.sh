#!/bin/bash
set -e

echo "=== Xcode Cloud: Post-Clone Script ==="

# Install Homebrew (Xcode Cloud runners have it, but ensure it's available)
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install XcodeGen (project is generated from project.yml)
echo "Installing XcodeGen..."
brew install xcodegen

# SundeeFundeeShared is inlined in the repo at SundeeFundee/Packages/SundeeFundeeShared
echo "Verifying SundeeFundeeShared package..."
if [ ! -f "$CI_PRIMARY_REPOSITORY_PATH/SundeeFundee/Packages/SundeeFundeeShared/Package.swift" ]; then
    echo "ERROR: SundeeFundeeShared/Package.swift not found in repo"
    ls -la "$CI_PRIMARY_REPOSITORY_PATH/SundeeFundee/Packages/" 2>/dev/null || echo "Packages dir missing"
    exit 1
fi
echo "SundeeFundeeShared found."

# Generate the Xcode project
echo "Generating Xcode project..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "=== Post-Clone Complete ==="
