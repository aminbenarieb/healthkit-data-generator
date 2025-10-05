import HealthKit
import HealthKitDataGenerator
import Logging

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let logger = AppUILogger.userAction
    private let authLogger = AppUILogger.authorization
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var isCleaningInProgress = false
    @Published var isGeneratingInProgress = false
    @Published var cleaningMessage = ""
    @Published var cleaningProgress: Double? = nil
    
    private init() {}
    
    func requestAuthorization() async {
        authLogger.info("Requesting HealthKit authorization")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            authLogger.error("HealthKit is not available on this device")
            return
        }
        
        let readTypes = HealthKitConstants.authorizationReadTypes()
        let writeTypes = HealthKitConstants.authorizationWriteTypes()
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run { [weak self] in
                self?.isAuthorized = true
            }
            authLogger.info("✅ HealthKit authorization granted", metadata: [
                "readTypes": "\(readTypes.count)",
                "writeTypes": "\(writeTypes.count)"
            ])
        } catch {
            authLogger.error("❌ HealthKit authorization failed", metadata: [
                "error": "\(error.localizedDescription)"
            ])
        }
    }
    
    func cleanHealthData() {
        guard !isCleaningInProgress else { return }
        
        logger.info("🧹 Starting HealthKit data cleanup")
        
        isCleaningInProgress = true
        cleaningMessage = "Starting cleanup..."
        cleaningProgress = nil
        
        Task {
            HealthKitStoreCleaner(healthStore: healthStore).clean { (message: String, progress) in
                DispatchQueue.main.async { [weak self] in
                    self?.cleaningMessage = message
                    self?.cleaningProgress = progress
                    self?.logger.debug("Cleanup progress", metadata: [
                        "progress": "\(String(describing: progress))",
                        "message": "\(message)"
                    ])
                }
            }
            
            await MainActor.run { [weak self] in
                self?.isCleaningInProgress = false
                self?.cleaningMessage = "Cleanup completed"
                self?.cleaningProgress = 1.0
                self?.logger.info("✅ Cleanup completed")
            }
        }
    }
    
    func generateHealthData(count: UInt, profile: HealthProfile = .balanced) {
        guard !isGeneratingInProgress else {
            logger.warning("Generation already in progress, ignoring request")
            return
        }
        
        logger.info("🎯 User initiated generation", metadata: [
            "days": "\(count)",
            "profile": "\(profile.name)"
        ])
        
        isGeneratingInProgress = true
        
        Task {
            do {
                let hkGenerator = HealthKitDataGenerator(healthStore: healthStore)
                let shareTypes = HealthKitConstants.authorizationWriteTypes()
                
                // Create configuration with selected profile
                let config = SampleGenerationConfig(
                    profile: profile,
                    dateRange: .lastDays(count)
                )
                
                // Generate all samples with config
                try hkGenerator.generateAndPopulate(samplesTypes: shareTypes, config: config)
                
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                logger.info("✅ Health data generation completed", metadata: [
                    "days": "\(count)",
                    "profile": "\(profile.name)"
                ])
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                logger.error("❌ Health data generation failed", metadata: [
                    "error": "\(error.localizedDescription)"
                ])
            }
        }
    }
    
    func generateHealthData(config: SampleGenerationConfig) {
        guard !isGeneratingInProgress else {
            logger.warning("Generation already in progress, ignoring request")
            return
        }
        
        logger.info("🎯 User initiated custom config generation", metadata: [
            "profile": "\(config.profile.name)",
            "days": "\(config.dateRange.numberOfDays)"
        ])
        
        isGeneratingInProgress = true
        
        Task {
            do {
                let hkGenerator = HealthKitDataGenerator(healthStore: healthStore)
                let shareTypes = HealthKitConstants.authorizationWriteTypes()
                
                try hkGenerator.generateAndPopulate(samplesTypes: shareTypes, config: config)
                
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                logger.info("✅ Custom config generation completed")
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                logger.error("❌ Custom config generation failed", metadata: [
                    "error": "\(error.localizedDescription)"
                ])
            }
        }
    }
    
    func importFromJSON(_ jsonString: String) {
        guard !isGeneratingInProgress else {
            logger.warning("Generation already in progress, ignoring JSON import")
            return
        }
        
        logger.info("📥 User initiated JSON import", metadata: [
            "jsonLength": "\(jsonString.count)"
        ])
        
        isGeneratingInProgress = true
        
        Task {
            do {
                let hkGenerator = HealthKitDataGenerator(healthStore: healthStore)
                
                // Validate first
                logger.debug("Validating JSON before import")
                let isValid = try hkGenerator.validateLLMJSON(jsonString)
                guard isValid else {
                    throw NSError(domain: "HealthKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
                }
                
                // Import
                try hkGenerator.importFromLLMJSON(jsonString)
                
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                logger.info("✅ Successfully imported data from JSON")
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                logger.error("❌ JSON import failed", metadata: [
                    "error": "\(error.localizedDescription)"
                ])
            }
        }
    }
}
