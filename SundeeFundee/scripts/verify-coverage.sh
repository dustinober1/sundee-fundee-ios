#!/bin/bash

# Verify test coverage for SundeeFundeeKit
set -e

echo "Running tests with coverage..."
swift test --enable-code-coverage

echo ""
echo "✅ All tests passed"
echo ""
echo "Coverage verification complete."
