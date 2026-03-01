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

# Clone the shared package (sibling dependency)
# Xcode Cloud clones the main repo but not sibling directories.
# The package is referenced as ../SundeeFundeeShared in project.yml
echo "Cloning SundeeFundeeShared package..."
cd "$CI_PRIMARY_REPOSITORY_PATH/.."
if [ ! -d "SundeeFundeeShared" ]; then
    git clone https://github.com/dustinober1/sundee-fundee-shared.git SundeeFundeeShared
fi

# Generate the Xcode project
echo "Generating Xcode project..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "=== Post-Clone Complete ==="
