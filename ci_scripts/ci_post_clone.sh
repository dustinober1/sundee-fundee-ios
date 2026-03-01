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

# Clone the shared package into the expected location
# The package is referenced as SundeeFundee/Packages/SundeeFundeeShared in project.yml
echo "Cloning SundeeFundeeShared package..."
SHARED_PKG_DIR="$CI_PRIMARY_REPOSITORY_PATH/SundeeFundee/Packages/SundeeFundeeShared"
mkdir -p "$(dirname "$SHARED_PKG_DIR")"
if [ ! -d "$SHARED_PKG_DIR" ]; then
    git clone https://github.com/dustinober1/sundee-fundee-shared.git "$SHARED_PKG_DIR"
fi

# Generate the Xcode project
echo "Generating Xcode project..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "=== Post-Clone Complete ==="
