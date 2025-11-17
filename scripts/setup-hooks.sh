#!/bin/bash
# Setup script for Git hooks
# Internet Archive Apple TV

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Git hooks for Internet Archive Apple TV${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "${RED}❌ Error: Not a git repository${NC}"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
echo "Installing pre-commit hook..."
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    echo -e "${YELLOW}⚠️  Backing up existing pre-commit hook to pre-commit.backup${NC}"
    cp "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.backup"
fi

cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo -e "${GREEN}✅ Pre-commit hook installed${NC}"

# Check for SwiftLint
echo ""
echo "Checking for SwiftLint..."
if command -v swiftlint &> /dev/null; then
    SWIFTLINT_VERSION=$(swiftlint version)
    echo -e "${GREEN}✅ SwiftLint $SWIFTLINT_VERSION is installed${NC}"
else
    echo -e "${YELLOW}⚠️  SwiftLint is not installed${NC}"
    echo ""
    echo "Please install SwiftLint using one of these methods:"
    echo ""
    echo "  1. Homebrew (recommended):"
    echo "     brew install swiftlint"
    echo ""
    echo "  2. Mint:"
    echo "     mint install realm/SwiftLint"
    echo ""
    echo "  3. CocoaPods (after pod install):"
    echo "     Pods/SwiftLint/swiftlint"
    echo ""
fi

# Check for .swiftlint.yml
if [ -f "$PROJECT_ROOT/.swiftlint.yml" ]; then
    echo -e "${GREEN}✅ SwiftLint configuration file found${NC}"
else
    echo -e "${RED}❌ SwiftLint configuration file not found${NC}"
    echo "Please ensure .swiftlint.yml exists in the project root"
fi

echo ""
echo -e "${GREEN}🎉 Git hooks setup complete!${NC}"
echo ""
echo "The pre-commit hook will now run SwiftLint on staged Swift files"
echo "before each commit."
echo ""
echo "To bypass the hook (not recommended), use:"
echo "  git commit --no-verify"
echo ""
