#!/usr/bin/env bash
# Global iOS Development Tools Installer
# Installs and configures all necessary tools for iOS quality system
# Run this once on a new machine

set -euo pipefail

echo "🛠️  Installing iOS Development Quality Tools..."

# --- Check if Homebrew is installed ---
if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew not found. Install from: https://brew.sh"
    exit 1
fi
echo "✅ Homebrew found"

# --- Install SwiftLint and SwiftFormat ---
echo "📦 Installing SwiftLint and SwiftFormat..."
brew install swiftlint swiftformat

# --- Install xcpretty ---
echo "💎 Installing xcpretty..."
if gem install xcpretty --user-install; then
    echo "✅ xcpretty installed to user directory"
    
    # Add gem path to shell configurations
    GEM_PATH="$HOME/.gem/ruby/2.6.0/bin"
    
    # Add to .zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "$GEM_PATH" "$HOME/.zshrc"; then
            echo "export PATH=\"$GEM_PATH:\$PATH\"" >> "$HOME/.zshrc"
            echo "✅ Added gem path to .zshrc"
        fi
    fi
    
    # Add to .bash_profile if it exists
    if [[ -f "$HOME/.bash_profile" ]]; then
        if ! grep -q "$GEM_PATH" "$HOME/.bash_profile"; then
            echo "export PATH=\"$GEM_PATH:\$PATH\"" >> "$HOME/.bash_profile"
            echo "✅ Added gem path to .bash_profile"
        fi
    fi
    
    # Export for current session
    export PATH="$GEM_PATH:$PATH"
else
    echo "⚠️  xcpretty installation failed, trying with sudo..."
    sudo gem install xcpretty
fi

# --- Configure Xcode if available ---
if [[ -d "/Applications/Xcode.app" ]]; then
    echo "🔧 Configuring Xcode developer tools..."
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    echo "✅ Xcode configured"
else
    echo "⚠️  Xcode not found. Install from Mac App Store for full functionality."
fi

# --- Verify installations ---
echo ""
echo "🔍 Verifying tool installations..."

if command -v swiftlint >/dev/null 2>&1; then
    echo "✅ SwiftLint: $(swiftlint version)"
else
    echo "❌ SwiftLint not found"
fi

if command -v swiftformat >/dev/null 2>&1; then
    echo "✅ SwiftFormat: $(swiftformat --version)"
else
    echo "❌ SwiftFormat not found"
fi

if command -v xcpretty >/dev/null 2>&1; then
    echo "✅ xcpretty: $(xcpretty --version)"
else
    echo "❌ xcpretty not found"
fi

if command -v xcodebuild >/dev/null 2>&1; then
    echo "✅ xcodebuild: $(xcodebuild -version | head -n1)"
else
    echo "❌ xcodebuild not found"
fi

echo ""
echo "🎉 iOS development tools setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Navigate to any iOS project directory"
echo "3. Run: ./setup-ios-quality.sh ProjectName SchemeName"
echo ""
echo "🔗 To get the setup script in any new project:"
echo "   curl -O https://raw.githubusercontent.com/knportal/MileTracker/main/setup-ios-quality.sh"
