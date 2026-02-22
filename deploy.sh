#!/bin/bash

# Sundee Fundee Deploy Script
# Iteration: Build & Deploy Flutter Web to Firebase Hosting

# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting build and deploy process...${NC}"

# Navigate to flutter_app directory
echo -e "${BLUE}📦 Navigating to flutter_app...${NC}"
cd flutter_app

# Get dependencies
echo -e "${BLUE}📥 Getting Flutter dependencies...${NC}"
flutter pub get

# Build Flutter Web
# Using --web-renderer canvaskit for performance, but you can change to html if needed
echo -e "${BLUE}🏗 Building Flutter Web (ENABLE_FIREBASE=true)...${NC}"
flutter build web --dart-define=ENABLE_FIREBASE=true --web-renderer canvaskit

# Navigate back to root
cd ..

# Deploy to Firebase
echo -e "${BLUE}🔥 Deploying to Firebase Hosting...${NC}"
firebase deploy --only hosting

echo -e "${GREEN}✅ Success! Application is live.${NC}"
