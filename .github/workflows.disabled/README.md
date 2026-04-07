# Workflows Disabled

These GitHub Actions workflows have been temporarily disabled.

## Files in this directory:
- `ci.yml` - Continuous Integration workflow
- `codeql.yml` - CodeQL security analysis workflow
- `release.yml` - Release automation workflow

## To re-enable workflows:

1. **Move files back to workflows directory:**
   ```bash
   mv .github/workflows.disabled/*.yml .github/workflows/
   ```

2. **Or rename this directory:**
   ```bash
   mv .github/workflows.disabled .github/workflows
   ```

## Note:

Before re-enabling, make sure to update the folder names in the workflows:
- `HealthGeneratorApp` → `HealthDataGeneratorApp`
- `HealthGeneratorApp.xcworkspace` → `HealthDataGeneratorApp.xcworkspace`
- `-scheme HealthGeneratorApp` → `-scheme HealthDataGeneratorApp`

## Disabled on:
October 5, 2025
