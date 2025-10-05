#!/bin/bash

# Health Data Generator App - Rebuild and Run Script
# This script rebuilds the app and runs it on the booted simulator

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# App configuration
BUNDLE_ID="com.welltory.healthkit-data-generator"
APP_NAME="HealthKitDataGeneratorApp"
WORKSPACE="HealthKitDataGeneratorApp.xcworkspace"
SCHEME="HealthKitDataGeneratorApp"
CONFIGURATION="Debug"

echo -e "${BLUE}🏗️  Health Data Generator - Rebuild and Run${NC}"
echo "================================================"

# Get the current directory (should be the project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo -e "${YELLOW}📍 Working directory: $PROJECT_ROOT${NC}"

# Step 1: Find booted simulator
echo -e "\n${BLUE}📱 Finding booted simulator...${NC}"
BOOTED_DEVICE=$(xcrun simctl list devices booted | grep "Booted" | head -1)

if [ -z "$BOOTED_DEVICE" ]; then
    echo -e "${RED}❌ No booted simulator found. Please boot a simulator first.${NC}"
    echo -e "${YELLOW}💡 Tip: Open Simulator.app and boot a device, then run this script again.${NC}"
    exit 1
fi

# Extract device ID
DEVICE_ID=$(echo "$BOOTED_DEVICE" | sed -n 's/.*(\([A-F0-9-]*\)).*/\1/p')
DEVICE_NAME=$(echo "$BOOTED_DEVICE" | sed 's/ (.*$//')

echo -e "${GREEN}✅ Found booted device: $DEVICE_NAME${NC}"
echo -e "${GREEN}   Device ID: $DEVICE_ID${NC}"

# Step 2: Clean and build
echo -e "\n${BLUE}🧹 Cleaning and building project...${NC}"
xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=iOS Simulator,id=$DEVICE_ID" \
    clean build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Step 3: Find the built app
echo -e "\n${BLUE}📦 Locating built app...${NC}"
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "$APP_NAME.app" -path "*/Debug-iphonesimulator/*" | grep -v Index.noindex | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Could not find built app${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found app at: $APP_PATH${NC}"

# Step 4: Install app
echo -e "\n${BLUE}📲 Installing app on simulator...${NC}"
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ App installed successfully${NC}"
else
    echo -e "${RED}❌ App installation failed${NC}"
    exit 1
fi

# Step 5: Launch app
echo -e "\n${BLUE}🚀 Launching app...${NC}"
LAUNCH_OUTPUT=$(xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" 2>&1)

if [ $? -eq 0 ]; then
    # Extract process ID from launch output
    PROCESS_ID=$(echo "$LAUNCH_OUTPUT" | grep -o '[0-9]\+$')
    echo -e "${GREEN}✅ App launched successfully${NC}"
    echo -e "${GREEN}   Process ID: $PROCESS_ID${NC}"
else
    echo -e "${RED}❌ App launch failed${NC}"
    echo "$LAUNCH_OUTPUT"
    exit 1
fi

# Step 6: Open Simulator app (if not already open)
echo -e "\n${BLUE}📱 Opening Simulator app...${NC}"
open -a Simulator

echo -e "\n${GREEN}🎉 SUCCESS! Health Data Generator is now running on $DEVICE_NAME${NC}"
echo -e "${YELLOW}💡 The app should now be visible in the Simulator window${NC}"
echo ""
echo -e "${BLUE}App Details:${NC}"
echo -e "  Bundle ID: $BUNDLE_ID"
echo -e "  Device: $DEVICE_NAME ($DEVICE_ID)"
echo -e "  Process ID: $PROCESS_ID"
echo ""
echo -e "${YELLOW}🔧 To stop the app, run:${NC}"
echo -e "  xcrun simctl terminate $DEVICE_ID $BUNDLE_ID"
