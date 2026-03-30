import SwiftUI
import HealthKitDataGenerator
import Logging

@main
struct HealthKitDataGeneratorApp: App {
    
    init() {
        // Bootstrap logging
        AppLogger.bootstrap(logLevel: .info)
        
        // Log app launch
        AppUILogger.lifecycle.info("🚀 App launched")
    }
    
    var body: some Scene {
        WindowGroup {
            ChatContentView()
        }
    }
}
