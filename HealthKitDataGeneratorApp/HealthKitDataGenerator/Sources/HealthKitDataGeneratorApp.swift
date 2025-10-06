import SwiftUI
import HealthKitDataGenerator
import Logging

@main
struct HealthKitDataGeneratorApp: App {
    
    init() {
        // Bootstrap logging with debug level for development
        AppLogger.bootstrap(logLevel: .debug)
        
        // Log app launch
        AppUILogger.lifecycle.info("🚀 App launched")
    }
    
    var body: some Scene {
        WindowGroup {
            ChatContentView()
        }
    }
}
