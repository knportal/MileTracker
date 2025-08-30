#!/usr/bin/env bash
# iOS Project Creator with Quality System
# Creates a new iOS project directory with all quality tools pre-configured
# Usage: ./create-ios-project.sh ProjectName

set -euo pipefail

PROJECT_NAME="${1:-}"

if [[ -z "$PROJECT_NAME" ]]; then
    echo "❌ Usage: $0 <ProjectName>"
    echo "   Example: $0 MyAwesomeApp"
    exit 1
fi

echo "🚀 Creating new iOS project: $PROJECT_NAME"

# --- Create project directory ---
if [[ -d "$PROJECT_NAME" ]]; then
    echo "❌ Directory $PROJECT_NAME already exists"
    exit 1
fi

mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# --- Initialize git repository ---
echo "📁 Initializing git repository..."
git init
git config core.hooksPath .git/hooks

# --- Download and run setup script ---
echo "⬇️  Setting up quality system..."

# Copy the setup script from current directory or download
if [[ -f "../setup-ios-quality.sh" ]]; then
    cp "../setup-ios-quality.sh" .
else
    echo "📥 Downloading setup script..."
    curl -sL -o setup-ios-quality.sh "https://raw.githubusercontent.com/knportal/MileTracker/main/setup-ios-quality.sh"
    chmod +x setup-ios-quality.sh
fi

# --- Run setup ---
./setup-ios-quality.sh "$PROJECT_NAME" "$PROJECT_NAME"

# --- Create initial README ---
echo "📝 Creating README.md..."
cat > README.md << EOF
# $PROJECT_NAME

## 🎯 Project Overview

[Add your project description here]

## 🛠️ Development Setup

This project uses automated code quality tools:

- **SwiftLint**: Code quality enforcement
- **SwiftFormat**: Automatic code formatting  
- **Git Hooks**: Pre-commit formatting, pre-push testing
- **Health Checks**: Repository validation

### Quick Start

1. **Clone the repository**
   \`\`\`bash
   git clone [repository-url]
   cd $PROJECT_NAME
   \`\`\`

2. **Install development tools** (first time only)
   \`\`\`bash
   brew install swiftlint swiftformat
   gem install xcpretty --user-install
   \`\`\`

3. **Open in Xcode**
   \`\`\`bash
   open $PROJECT_NAME.xcodeproj
   # or
   open $PROJECT_NAME.xcworkspace
   \`\`\`

4. **Add Xcode Run Script Phase** (see SETUP_INSTRUCTIONS.md)

## 🚀 Development Workflow

### Code Quality Enforcement

- **Commit**: Code automatically formatted
- **Push**: Health checks + unit tests run
- **Build**: Xcode validates formatting and lint rules

### Making Changes

1. Make your changes
2. Commit (automatic formatting applied)
3. Push (tests must pass)

## 📋 Project Structure

\`\`\`
$PROJECT_NAME/
├── $PROJECT_NAME/           # Main app source
├── ${PROJECT_NAME}Tests/    # Unit tests
├── Scripts/                 # Build and health scripts
├── .swiftlint.yml          # SwiftLint configuration
├── .swiftformat            # SwiftFormat configuration
└── SETUP_INSTRUCTIONS.md   # Detailed setup guide
\`\`\`

## 🔧 Customization

- **Lint rules**: Edit \`.swiftlint.yml\`
- **Format style**: Edit \`.swiftformat\`  
- **Health checks**: Modify \`Scripts/healthcheck.sh\`

## 🆘 Troubleshooting

See \`SETUP_INSTRUCTIONS.md\` for detailed setup and troubleshooting guide.
EOF

# --- Create initial commit ---
echo "📝 Creating initial commit..."
git add .
git commit -m "Initial commit with quality system setup

- Added SwiftLint and SwiftFormat configuration
- Configured Git hooks for code quality
- Added health check script
- Set up project structure with quality tools"

echo ""
echo "🎉 Project $PROJECT_NAME created successfully!"
echo ""
echo "📋 Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. Create your Xcode project in this directory"
echo "3. Add the Xcode Run Script Phase (see SETUP_INSTRUCTIONS.md)"
echo "4. Start coding with automatic quality enforcement!"
echo ""
echo "🔗 Your project is ready with:"
echo "   ✅ Git repository initialized"
echo "   ✅ Quality tools configured"  
echo "   ✅ Git hooks installed"
echo "   ✅ Documentation created"
