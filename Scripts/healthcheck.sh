#!/usr/bin/env bash
# Repository health check script
# Runs basic checks to ensure code quality before push

set -euo pipefail

echo "🔍 Running repository health checks..."

# Check 1: SwiftLint configuration exists
if [[ ! -f ".swiftlint.yml" ]]; then
    echo "❌ SwiftLint configuration missing"
    exit 1
fi
echo "✅ SwiftLint configuration found"

# Check 2: SwiftFormat configuration exists  
if [[ ! -f ".swiftformat" ]]; then
    echo "❌ SwiftFormat configuration missing"
    exit 1
fi
echo "✅ SwiftFormat configuration found"

# Check 3: Check for any uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️  Warning: Uncommitted changes detected"
    git status --short
else
    echo "✅ No uncommitted changes"
fi

# Check 4: Verify Swift files exist
SWIFT_FILES=$(find . -name "*.swift" -not -path "./.git/*" | wc -l)
if [[ $SWIFT_FILES -eq 0 ]]; then
    echo "❌ No Swift files found"
    exit 1
fi
echo "✅ Found $SWIFT_FILES Swift files"

# Check 5: Basic project structure
if [[ ! -d "MileTracker" ]]; then
    echo "❌ MileTracker directory missing"
    exit 1
fi
echo "✅ Project structure valid"

# Check 6: Verify Xcode project exists
if [[ ! -f "MileTracker/MileTracker.xcodeproj/project.pbxproj" ]]; then
    echo "❌ Xcode project file missing"
    exit 1
fi
echo "✅ Xcode project file found"

echo "🎉 All health checks passed!"
