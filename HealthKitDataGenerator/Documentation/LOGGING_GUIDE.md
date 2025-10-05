# Logging Guide

## Overview

HealthKit Data Generator uses [Apple's swift-log](https://github.com/apple/swift-log) for structured, performant logging with separate subsystems for the package and app.

## Architecture

### Two Subsystems

1. **Package Subsystem** (`com.welltory.healthkit-data-generator.package`)
   - Used by the SPM package
   - Categories: generation, import, export, validation, llm, healthkit, profile, general

2. **App Subsystem** (`com.welltory.healthkit-data-generator.app`)
   - Used by the iOS app
   - Categories: ui, lifecycle, user-action, authorization

This separation allows you to:
- Filter logs by source (package vs app)
- Save package logs and app logs to different files
- Debug package issues independently from app issues

## Usage

### In Package Code

```swift
import Logging

// Use the appropriate logger for your operation
AppLogger.generation.info("Starting generation")
AppLogger.validation.warning("Invalid value detected")
AppLogger.llm.error("Failed to parse JSON")
```

### In App Code

```swift
import Logging

// Use app-specific loggers
AppUILogger.userAction.info("User tapped generate button")
AppUILogger.authorization.info("Requesting HealthKit permissions")
AppUILogger.lifecycle.info("App launched")
```

### Log Levels

```swift
logger.trace("Very detailed information")    // Most verbose
logger.debug("Debugging information")        // Development
logger.info("General information")           // Default
logger.notice("Important information")       // Significant events
logger.warning("Warning messages")           // Potential issues
logger.error("Error messages")               // Errors
logger.critical("Critical errors")           // Critical failures
```

### Structured Metadata

```swift
logger.info("Generation complete", metadata: [
    "days": "\(days)",
    "samples": "\(totalSamples)",
    "profile": "\(profileName)"
])
```

## Viewing Logs

### Console.app (macOS)

1. Open Console.app
2. Select your device/simulator
3. Filter by subsystem:
   - Package logs: `subsystem:com.welltory.healthkit-data-generator.package`
   - App logs: `subsystem:com.welltory.healthkit-data-generator.app`
4. Filter by category:
   - `category:generation`
   - `category:user-action`
   - etc.

### Xcode Console

Logs appear in Xcode's console when running the app. Format:
```
[timestamp] [level] [label] message metadata
```

### Command Line (Simulator)

```bash
# Stream all logs
xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "healthkit-data-generator"'

# Package logs only
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.welltory.healthkit-data-generator.package"'

# App logs only
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.welltory.healthkit-data-generator.app"'

# Specific category
xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "healthkit-data-generator" AND category == "generation"'
```

## Exporting Logs to Files

### Option 1: Configure File Logging (Recommended)

```swift
// In your app startup
import HealthKitDataGenerator

let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let logsDirectory = documentsURL.appendingPathComponent("Logs")

try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

// Configure file logging
try? AppLogger.configureFileLogging(logDirectory: logsDirectory)

// Now all logs will be written to:
// - package.log (for package logs)
```

### Option 2: Export from Console

```bash
# Export last 24 hours of package logs
log show --predicate 'subsystem == "com.welltory.healthkit-data-generator.package"' --last 24h > package_logs.txt

# Export last 24 hours of app logs
log show --predicate 'subsystem == "com.welltory.healthkit-data-generator.app"' --last 24h > app_logs.txt

# Export specific category
log show --predicate 'subsystem CONTAINS "healthkit-data-generator" AND category == "generation"' --last 24h > generation_logs.txt
```

### Option 3: Programmatic Export (iOS)

```swift
// In your app
Button("Export Logs") {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let logFile = documentsURL.appendingPathComponent("exported_logs.txt")
    
    // Note: This requires the FileLogHandler to be configured
    // Alternatively, use OSLog's store API (iOS 15+)
}
```

## Log Categories

### Package Categories

| Category | Purpose | Example |
|----------|---------|---------|
| `generation` | Sample generation | "Starting generation for 7 days" |
| `import` | Data import | "Importing 100 samples" |
| `export` | Data export | "Exporting to JSON" |
| `validation` | Validation | "Validating LLM JSON" |
| `llm` | LLM integration | "Decoded LLM data" |
| `healthkit` | HealthKit operations | "Saved to HealthKit" |
| `profile` | Profile operations | "Loaded profile: sporty" |
| `general` | General operations | "Initialized generator" |

### App Categories

| Category | Purpose | Example |
|----------|---------|---------|
| `ui` | UI operations | "View appeared" |
| `lifecycle` | App lifecycle | "App launched" |
| `user-action` | User actions | "User tapped generate" |
| `authorization` | HealthKit auth | "Authorization granted" |

## Best Practices

### 1. Use Appropriate Log Levels

```swift
// ✅ Good
logger.debug("Processing item", metadata: ["id": "\(id)"])  // Development info
logger.info("Generation started")                           // Important events
logger.warning("Retrying operation")                        // Potential issues
logger.error("Failed to save", metadata: ["error": "\(error)"]) // Errors

// ❌ Bad
logger.info("Loop iteration \(i)")  // Too verbose, use .debug
logger.error("User tapped button")  // Not an error, use .info
```

### 2. Use Structured Metadata

```swift
// ✅ Good - Structured and searchable
logger.info("Generation complete", metadata: [
    "days": "\(days)",
    "samples": "\(count)",
    "profile": "\(name)"
])

// ❌ Bad - Unstructured
logger.info("Generation complete with \(days) days and \(count) samples for \(name)")
```

### 3. Include Context

```swift
// ✅ Good
logger.error("Failed to decode JSON", metadata: [
    "error": "\(error.localizedDescription)",
    "jsonLength": "\(jsonString.count)",
    "schemaVersion": "\(version)"
])

// ❌ Bad
logger.error("Failed")
```

### 4. Use Emojis for Quick Visual Scanning

```swift
logger.info("🚀 Starting generation")
logger.info("✅ Generation complete")
logger.error("❌ Generation failed")
logger.warning("⚠️ Validation warning")
logger.debug("📊 Generated metric")
```

## Performance Considerations

- Logging is **very fast** with swift-log
- Debug logs are automatically stripped in Release builds
- Metadata is lazily evaluated
- No performance impact in production

## Debugging Tips

### Find Errors Only

```bash
log show --predicate 'subsystem CONTAINS "healthkit-data-generator" AND messageType == error' --last 1h
```

### Find Specific Operation

```bash
log show --predicate 'subsystem CONTAINS "healthkit-data-generator" AND eventMessage CONTAINS "generation"' --last 1h
```

### Monitor in Real-Time

```bash
log stream --predicate 'subsystem CONTAINS "healthkit-data-generator"' --level debug
```

## Example Log Output

```
[2025-10-05 16:00:00] [info] [package.generation] 🎯 Starting sample generation profile="Athletic" days="7" metrics="6" pattern="continuous"
[2025-10-05 16:00:00] [debug] [package.generation] Generated metric samples metric="steps" date="Oct 5" count="12"
[2025-10-05 16:00:00] [debug] [package.generation] Generated metric samples metric="heart_rate" date="Oct 5" count="48"
[2025-10-05 16:00:00] [debug] [package.generation] Day complete date="Oct 5" samples="60"
[2025-10-05 16:00:01] [info] [package.generation] ✅ Sample generation complete daysProcessed="7" totalSamples="420" metricTypes="6"
[2025-10-05 16:00:01] [info] [app.user-action] ✅ Health data generation completed days="7" profile="Athletic"
```

## Configuration

### Set Log Level

```swift
// In your app startup (AppDelegate or @main)
AppLogger.bootstrap(logLevel: .debug)  // For development
AppLogger.bootstrap(logLevel: .info)   // For production
```

### Custom Log Handler

```swift
import Logging

LoggingSystem.bootstrap { label in
    // Use your custom handler
    var handler = MyCustomLogHandler(label: label)
    handler.logLevel = .info
    return handler
}
```

## Troubleshooting

### Logs Not Appearing?

1. Check log level is set appropriately
2. Verify subsystem/category filters in Console.app
3. Ensure logging is bootstrapped before use
4. Check device/simulator logs, not just Xcode console

### Too Many Logs?

1. Increase log level to `.info` or `.warning`
2. Filter by specific categories
3. Use `.debug` only during development

### Need Historical Logs?

1. Configure FileLogHandler at app startup
2. Or use `log show` command with time range
3. Or use OSLog's persistent store API (iOS 15+)

---

For more information, see:
- [Apple's swift-log documentation](https://github.com/apple/swift-log)
- [OSLog documentation](https://developer.apple.com/documentation/oslog)
- [Console.app user guide](https://support.apple.com/guide/console/welcome/mac)
