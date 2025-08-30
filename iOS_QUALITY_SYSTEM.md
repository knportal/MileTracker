# 🏆 iOS Project Quality System

## 🚀 Quick Setup for New Projects

### Option 1: Use Project Creator (Recommended)
```bash
# Download the creator script
curl -O https://raw.githubusercontent.com/knportal/MileTracker/main/create-ios-project.sh
chmod +x create-ios-project.sh

# Create new project with quality system
./create-ios-project.sh MyNewApp
cd MyNewApp
# Create your Xcode project here, then add Run Script Phase
```

### Option 2: Add to Existing Project
```bash
# In your existing project directory
curl -O https://raw.githubusercontent.com/knportal/MileTracker/main/setup-ios-quality.sh
chmod +x setup-ios-quality.sh
./setup-ios-quality.sh YourProjectName YourSchemeName
```

## 🛠️ One-Time Machine Setup

```bash
# Install all necessary tools (run once per machine)
curl -O https://raw.githubusercontent.com/knportal/MileTracker/main/install-ios-tools.sh
chmod +x install-ios-tools.sh
./install-ios-tools.sh
```

## 📋 What You Get

### 🔧 Configuration Files
- **`.swiftlint.yml`** - Code quality rules
- **`.swiftformat`** - Code formatting rules
- **`Scripts/healthcheck.sh`** - Repository health validation

### 🪝 Git Hooks
- **Pre-commit** - Automatic code formatting
- **Pre-push** - Health checks + unit tests

### 📱 Xcode Integration
- **Run Script Phase** - Build-time quality checks
- **Build failure** on quality violations

## 🎯 Development Workflow

```mermaid
graph LR
    A[Write Code] --> B[Commit]
    B --> C[Auto Format]
    C --> D[Push]
    D --> E[Health Check]
    E --> F[Run Tests]
    F --> G[Deploy]
    
    style C fill:#c8e6c9
    style E fill:#fff3e0
    style F fill:#e1f5fe
```

### Commit Stage
1. **Write code** in Xcode
2. **Build locally** - Run Script Phase validates quality
3. **Commit changes** - Pre-commit hook formats code automatically
4. **Code is consistently formatted** ✨

### Push Stage
1. **Push to remote** - Pre-push hook triggers
2. **Health check runs** - Validates repository structure
3. **Unit tests execute** - Ensures functionality
4. **Push succeeds** only if all checks pass 🛡️

## 🔄 Updating Existing Projects

### Add Quality System to Any Project
```bash
# In your project root
git clone https://github.com/knportal/MileTracker.git temp
cp temp/setup-ios-quality.sh .
rm -rf temp
./setup-ios-quality.sh YourProjectName YourSchemeName
```

### Update Configuration
```bash
# Get latest configurations
curl -O https://raw.githubusercontent.com/knportal/MileTracker/main/.swiftlint.yml
curl -O https://raw.githubusercontent.com/knportal/MileTracker/main/.swiftformat
curl -O https://raw.githubusercontent.com/knportal/MileTracker/main/Scripts/healthcheck.sh
chmod +x Scripts/healthcheck.sh
```

## 📱 Simulator Configuration

### Available Simulators
```bash
# List available simulators
xcrun simctl list devices
```

### Update Hook Simulator
Edit `.git/hooks/pre-push`:
```bash
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
```

## 🎛️ Customization

### SwiftLint Rules (.swiftlint.yml)
```yaml
disabled_rules:
  - line_length  # Add rules you want to disable

opt_in_rules:
  - empty_count  # Add extra quality rules
```

### SwiftFormat Style (.swiftformat)
```bash
--indent 4           # 4-space indentation
--maxwidth 100       # 100 character line limit
--semicolons never   # No semicolons in Swift
```

### Health Checks (Scripts/healthcheck.sh)
Add custom validation:
```bash
# Check for specific files
if [[ ! -f "MyRequiredFile.swift" ]]; then
    echo "❌ Required file missing"
    exit 1
fi
```

## 🚨 Troubleshooting

### Common Issues

**SwiftLint SourceKit Crashes**
- Hooks handle this gracefully
- Formatting still works
- Non-blocking for development

**Missing Tools**
```bash
brew install swiftlint swiftformat
gem install xcpretty --user-install
```

**Xcode Not Configured**
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Git Hooks Not Running**
```bash
# Ensure hooks are executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
```

### Bypass Hooks (Emergency)
```bash
# Skip pre-commit (not recommended)
git commit --no-verify -m "emergency fix"

# Skip pre-push (not recommended)  
git push --no-verify
```

## 📊 Quality Metrics

Your projects will have:

✅ **Consistent Code Style** - SwiftFormat ensures uniformity  
✅ **Quality Standards** - SwiftLint enforces best practices  
✅ **Automated Testing** - Pre-push hooks run tests  
✅ **Health Validation** - Repository structure checks  
✅ **Build Integration** - Xcode validates quality  

## 🔗 Resources

- **SwiftLint**: [GitHub](https://github.com/realm/SwiftLint)
- **SwiftFormat**: [GitHub](https://github.com/nicklockwood/SwiftFormat)
- **Apple Swift Guidelines**: [Documentation](https://swift.org/documentation/api-design-guidelines/)

## 📞 Support

For issues with this quality system:
1. Check `SETUP_INSTRUCTIONS.md` in your project
2. Verify tool installations: `brew list | grep swift`
3. Test individual components: `swiftlint`, `swiftformat .`

---

**🎉 Happy coding with enterprise-grade quality assurance!**
