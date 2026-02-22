#!/bin/bash

# Sundee Fundee Local Run Script
# Iteration: Run Flutter Web locally with Firebase enabled

# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Preparing to run Sundee-Fundee locally...${NC}"

# Navigate to flutter_app directory
echo -e "${BLUE}📦 Navigating to flutter_app...${NC}"
cd flutter_app

# Get dependencies
echo -e "${BLUE}📥 Getting Flutter dependencies...${NC}"
flutter pub get

# Run Flutter Web
echo -e "${BLUE}🏗 Starting local development server (ENABLE_FIREBASE=true)...${NC}"
echo -e "${BLUE}🌐 This will open in Chrome by default.${NC}"
flutter run -d chrome --dart-define=ENABLE_FIREBASE=true
