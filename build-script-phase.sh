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
