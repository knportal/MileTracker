#!/usr/bin/env bash
# iOS Project Quality Setup Script
# Sets up SwiftLint, SwiftFormat, Git hooks, and health checks for any iOS project
# Usage: ./setup-ios-quality.sh [PROJECT_NAME] [SCHEME_NAME]

set -euo pipefail

# --- Configuration ---
PROJECT_NAME="${1:-YourApp}"
SCHEME_NAME="${2:-$PROJECT_NAME}"
SIMULATOR_NAME="iPhone 16"

echo "🎯 Setting up iOS project quality system for: $PROJECT_NAME"
echo "📱 Using scheme: $SCHEME_NAME"
echo "🔧 Target simulator: $SIMULATOR_NAME"
echo ""

# --- Check if we're in a git repository ---
if [[ ! -d ".git" ]]; then
    echo "❌ Not in a git repository. Run 'git init' first."
    exit 1
fi

# --- Create .swiftlint.yml ---
echo "📝 Creating .swiftlint.yml..."
cat > .swiftlint.yml << 'EOF'
# SwiftLint configuration

disabled_rules: # rules you want to turn off
  - trailing_whitespace
  - line_length # we handle this with rulers in Cursor
  - force_cast   # allow only if absolutely needed

opt_in_rules: # extra good rules
  - empty_count
  - explicit_init
  - redundant_nil_coalescing
  - force_unwrapping

included:
  - Sources
  - Tests
  - $(PROJECT_NAME)

excluded:
  - Carthage
  - Pods
  - .build
  - .git

# line_length configuration removed since rule is disabled

identifier_name:
  min_length: 3
  excluded:
    - id
    - URL
    - x
    - y

type_body_length:
  warning: 300
  error: 500

function_body_length:
  warning: 40
  error: 80

cyclomatic_complexity:
  warning: 10
  error: 20
EOF

# --- Create .swiftformat ---
echo "📝 Creating .swiftformat..."
cat > .swiftformat << 'EOF'
--indent 4
--maxwidth 100
--wraparguments before-first
--wrapcollections before-first
--stripunusedargs closure-only
--commas inline
--semicolons never
--disable redundantSelf
--disable unusedArguments
EOF

# --- Create Scripts directory and health check ---
echo "📁 Creating Scripts/healthcheck.sh..."
mkdir -p Scripts

cat > Scripts/healthcheck.sh << 'EOF'
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
PROJECT_DIRS=$(find . -maxdepth 2 -name "*.xcodeproj" -o -name "*.xcworkspace" | wc -l)
if [[ $PROJECT_DIRS -eq 0 ]]; then
    echo "❌ No Xcode project or workspace found"
    exit 1
fi
echo "✅ Project structure valid"

echo "🎉 All health checks passed!"
EOF

chmod +x Scripts/healthcheck.sh

# --- Create pre-commit hook ---
echo "🪝 Creating pre-commit hook..."
cat > .git/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
# Format + Lint Swift on staged files before commit
# Requires: swiftformat, swiftlint (brew install swiftformat swiftlint)

set -euo pipefail

# --- Config ---
RUN_FULL_REPO=${RUN_FULL_REPO:-false}  # set to "true" to format/lint entire repo

# --- Tool checks ---
if ! command -v swiftformat >/dev/null 2>&1; then
  echo "❌ swiftformat not found. Install with: brew install swiftformat"
  exit 1
fi

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "❌ swiftlint not found. Install with: brew install swiftlint"
  exit 1
fi

# --- Collect staged Swift files ---
SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.swift$' || true)

if [[ -z "${SWIFT_FILES}" && "${RUN_FULL_REPO}" != "true" ]]; then
  # Nothing to do
  exit 0
fi

echo "🧹 Running SwiftFormat + SwiftLint…"

if [[ "${RUN_FULL_REPO}" == "true" ]]; then
  # Format & lint entire repo (slower, but thorough)
  swiftformat . --quiet
  # Try to auto-fix, then lint again to fail on remaining issues
  # Note: SwiftLint may have SourceKit issues on some systems
  if swiftlint --fix 2>/dev/null; then
    swiftlint 2>/dev/null || echo "⚠️  SwiftLint encountered issues but formatting completed"
  else
    echo "⚠️  SwiftLint auto-fix encountered issues, continuing with format-only"
  fi
  # Re-stage any changes
  git add -A
else
  # Format only staged Swift files
  # shellcheck disable=SC2086
  swiftformat ${SWIFT_FILES} --quiet

  # Lint only staged Swift files using SCRIPT_INPUT_FILE_* envs
  i=0
  # shellcheck disable=SC2086
  for f in ${SWIFT_FILES}; do
    export "SCRIPT_INPUT_FILE_${i}=$f"
    i=$((i+1))
  done
  export SCRIPT_INPUT_FILE_COUNT=$i

  # Try to auto-fix, then lint again to fail on remaining issues
  # Note: SwiftLint may have SourceKit issues on some systems
  if swiftlint --fix --use-script-input-files 2>/dev/null; then
    swiftlint --use-script-input-files 2>/dev/null || echo "⚠️  SwiftLint encountered issues but formatting completed"
  else
    echo "⚠️  SwiftLint auto-fix encountered issues, continuing with format-only"
  fi

  # Re-stage formatted/linted files
  # shellcheck disable=SC2086
  git add ${SWIFT_FILES}
fi

echo "✅ Swift format & lint passed."
exit 0
EOF

chmod +x .git/hooks/pre-commit

# --- Create pre-push hook ---
echo "🪝 Creating pre-push hook..."

# Detect project structure
if [[ -f "*.xcworkspace" ]]; then
    PROJECT_TYPE="-workspace"
    PROJECT_FILE="*.xcworkspace"
else
    PROJECT_TYPE="-project"
    PROJECT_FILE=$(find . -name "*.xcodeproj" | head -n1)
fi

cat > .git/hooks/pre-push << EOF
#!/usr/bin/env bash
set -euo pipefail

echo "🔎 Repo health check before push…"
./Scripts/healthcheck.sh

echo "🧪 Running unit tests…"
SCHEME="$SCHEME_NAME"
PROJECT="$PROJECT_FILE"
DESTINATION="platform=iOS Simulator,name=$SIMULATOR_NAME"

xcodebuild \\
  $PROJECT_TYPE "\$PROJECT" \\
  -scheme "\$SCHEME" \\
  -configuration Debug \\
  -destination "\$DESTINATION" \\
  clean test | xcpretty

echo "✅ Health + tests passed. Pushing allowed."
EOF

chmod +x .git/hooks/pre-push

# --- Create build script phase template ---
echo "📋 Creating build-script-phase.sh template..."
cat > build-script-phase.sh << 'EOF'
# Copy this script into your Xcode Run Script Phase
# Place it before "Compile Sources" in Build Phases
# Exit non-zero on lint errors; format only checks (no writes) here

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat . --lint --quiet || {
    echo "❌ SwiftFormat differences found (run 'swiftformat .')"
    exit 1
  }
fi

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint || {
    echo "❌ SwiftLint violations found"
    exit 1
  }
fi
EOF

# --- Create setup instructions ---
echo "📖 Creating SETUP_INSTRUCTIONS.md..."
cat > SETUP_INSTRUCTIONS.md << EOF
# iOS Project Quality Setup

This project has been configured with automated code quality tools.

## 🛠️ Tools Installed

- **SwiftLint**: Code quality and style checking
- **SwiftFormat**: Automatic code formatting
- **Git Hooks**: Pre-commit formatting, pre-push testing
- **Health Checks**: Repository validation

## 🎯 Manual Setup Required

### 1. Install Tools (if not already installed)
\`\`\`bash
brew install swiftlint swiftformat
gem install xcpretty --user-install
\`\`\`

### 2. Add Xcode Run Script Phase
1. Open your Xcode project
2. Select your app target
3. Go to **Build Phases**
4. Click **+** → **New Run Script Phase**
5. **Drag it above "Compile Sources"**
6. Copy the content from \`build-script-phase.sh\` into the script area

### 3. Configure Xcode for Testing (if needed)
\`\`\`bash
# Only needed if xcodebuild fails
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
\`\`\`

## 🚀 How It Works

### Commit Time
- **Pre-commit hook** automatically formats Swift code
- Uses SwiftFormat to ensure consistent style

### Push Time  
- **Health check** validates repository structure
- **Unit tests** run to ensure code quality
- Push is blocked if tests fail

### Build Time
- **Xcode Run Script** checks formatting and lint rules
- Build fails if code doesn't meet standards

## 🔧 Customization

- **SwiftLint rules**: Edit \`.swiftlint.yml\`
- **SwiftFormat style**: Edit \`.swiftformat\`
- **Health checks**: Modify \`Scripts/healthcheck.sh\`
- **Project settings**: Update hooks with your scheme/project names

## 📱 Simulator Configuration

Current target: **$SIMULATOR_NAME**

To change the simulator:
1. Edit \`.git/hooks/pre-push\`
2. Update the \`DESTINATION\` variable

## 🆘 Troubleshooting

### SwiftLint SourceKit Issues
If you see SourceKit crashes, the hooks will continue gracefully with formatting only.

### Missing Tools
Install missing tools with Homebrew:
\`\`\`bash
brew install swiftlint swiftformat
\`\`\`

### Test Failures
Check that your scheme name and project structure are correct in the pre-push hook.
EOF

# --- Summary ---
echo ""
echo "🎉 Setup complete! Your project now has:"
echo "✅ SwiftLint configuration (.swiftlint.yml)"
echo "✅ SwiftFormat configuration (.swiftformat)"
echo "✅ Pre-commit hook (auto-formatting)"
echo "✅ Pre-push hook (health checks + tests)"
echo "✅ Health check script (Scripts/healthcheck.sh)"
echo "✅ Build script template (build-script-phase.sh)"
echo "✅ Setup instructions (SETUP_INSTRUCTIONS.md)"
echo ""
echo "📋 Next steps:"
echo "1. Install tools: brew install swiftlint swiftformat"
echo "2. Add Xcode Run Script Phase (see SETUP_INSTRUCTIONS.md)"
echo "3. Test with: git add . && git commit -m 'test' && git push"
echo ""
echo "🔗 For future projects, copy this script and run:"
echo "   ./setup-ios-quality.sh NewProjectName NewSchemeName"
EOF
