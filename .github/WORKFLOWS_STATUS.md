# GitHub Workflows Status

## ✅ Workflows Disabled

All GitHub Actions workflows have been moved to `.github/workflows.disabled/` directory.

### What was done:
1. ✅ Copied all workflow files to `workflows.disabled/` directory
2. ⚠️  **Action Required**: Delete the original files in `workflows/` directory

### To complete the disabling:

```bash
# Delete the active workflow files
rm -rf .github/workflows/
```

### Workflows that were disabled:
- **ci.yml** - Continuous Integration (Swift Package tests, iOS app build, SwiftLint)
- **codeql.yml** - CodeQL security analysis
- **release.yml** - Automated releases on version tags

---

## 📝 Important Notes

### Before Re-enabling Workflows:

The workflows contain **outdated folder names** and need to be updated:

#### Changes needed:
1. **Folder name**: `HealthGeneratorApp` → `HealthKitDataGeneratorApp`
2. **Workspace**: `HealthGeneratorApp.xcworkspace` → `HealthKitDataGeneratorApp.xcworkspace`
3. **Scheme**: `-scheme HealthGeneratorApp` → `-scheme HealthKitDataGeneratorApp`

#### Files that need updates:
- `ci.yml` - Lines 68, 74, 84
- `codeql.yml` - Lines 45, 47
- `release.yml` - Lines 33, 39

---

## 🔄 To Re-enable Workflows:

### Option 1: Move files back (after updating)
```bash
# 1. Update the folder names in workflow files
# 2. Move back to workflows directory
mv .github/workflows.disabled/*.yml .github/workflows/
```

### Option 2: Rename directory
```bash
# After updating folder names in the files
mv .github/workflows.disabled .github/workflows
```

---

## 🧪 Testing Workflows Locally

Before re-enabling, you can test workflows locally:

### Using `act`:
```bash
# Install act
brew install act

# Test CI workflow
act -j test-swift-package
act -j build-ios-app
act -j lint
```

### Manual testing:
```bash
# Test Swift Package
cd HealthKitDataGenerator && swift build && swift test

# Test iOS App
cd HealthKitDataGeneratorApp && tuist generate

# Run SwiftLint
swiftlint lint
```

---

**Status**: Workflows disabled on October 5, 2025
**Reason**: Folder renaming from HealthGeneratorApp to HealthKitDataGeneratorApp
