#!/bin/bash
set -e

echo "=== Xcode Cloud: Pre-Xcodebuild Script ==="

# Verify the project was generated
if [ ! -d "$CI_PRIMARY_REPOSITORY_PATH/SundeeFundee.xcodeproj" ]; then
    echo "ERROR: SundeeFundee.xcodeproj not found. ci_post_clone.sh may have failed."
    exit 1
fi

# Verify shared package is available
if [ ! -d "$CI_PRIMARY_REPOSITORY_PATH/SundeeFundee/Packages/SundeeFundeeShared" ]; then
    echo "ERROR: SundeeFundeeShared not found."
    exit 1
fi

echo "Project and dependencies verified."
echo "=== Pre-Xcodebuild Complete ==="
