import SwiftUI
import HealthDataGenerator
import Logging

@main
struct HealthDataGeneratorApp: App {
    
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
