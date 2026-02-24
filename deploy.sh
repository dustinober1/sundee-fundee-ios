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
echo -e "${BLUE}🏗 Building Flutter Web (ENABLE_FIREBASE=true)...${NC}"
flutter build web --dart-define=ENABLE_FIREBASE=true --release

# Navigate back to root
cd ..

# Deploy app and firestore contract artifacts together
echo -e "${BLUE}🔥 Deploying Firebase Hosting + Firestore contract...${NC}"
firebase deploy --only firestore,firestore:indexes,hosting

echo -e "${GREEN}✅ Success! Application is live.${NC}"
