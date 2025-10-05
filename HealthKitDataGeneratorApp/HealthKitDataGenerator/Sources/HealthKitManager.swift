import HealthKit
import HealthKitDataGenerator
import OSLog

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private static let logger = Logger(subsystem: "HealthKitDataGeneratorApp", category: "HealthKitManager")
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var isCleaningInProgress = false
    @Published var isGeneratingInProgress = false
    @Published var cleaningMessage = ""
    @Published var cleaningProgress: Double? = nil
    
    private init() {}
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Self.logger.error("HealthKit is not available on this device")
            return
        }
        
        let readTypes = HealthKitConstants.authorizationReadTypes()
        let writeTypes = HealthKitConstants.authorizationWriteTypes()
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run { [weak self] in
                self?.isAuthorized = true
            }
            Self.logger.info("HealthKit authorization granted")
        } catch {
            Self.logger.error("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
    
    func cleanHealthData() {
        guard !isCleaningInProgress else { return }
        
        isCleaningInProgress = true
        cleaningMessage = "Starting cleanup..."
        cleaningProgress = nil
        
        Task {
            HealthKitStoreCleaner(healthStore: healthStore).clean { (message: String, progress) in
                DispatchQueue.main.async { [weak self] in
                    self?.cleaningMessage = message
                    self?.cleaningProgress = progress
                    Self.logger.debug("HealthKitStoreCleaner \(String(describing: progress)) progress - \(message)")
                }
            }
            
            await MainActor.run { [weak self] in
                self?.isCleaningInProgress = false
                self?.cleaningMessage = "Cleanup completed"
                self?.cleaningProgress = 1.0
            }
        }
    }
    
    func generateHealthData(count: Int, profile: HealthProfile = .balanced) {
        guard !isGeneratingInProgress else { return }
        
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
                Self.logger.info("Health data generation completed with \(count) days using \(profile.name) profile")
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                Self.logger.error("Health data generation failed: \(error.localizedDescription)")
            }
        }
    }
    
    func generateHealthData(config: SampleGenerationConfig) {
        guard !isGeneratingInProgress else { return }
        
        isGeneratingInProgress = true
        
        Task {
            do {
                let hkGenerator = HealthKitDataGenerator(healthStore: healthStore)
                let shareTypes = HealthKitConstants.authorizationWriteTypes()
                
                try hkGenerator.generateAndPopulate(samplesTypes: shareTypes, config: config)
                
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                Self.logger.info("Health data generation completed using custom config")
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                Self.logger.error("Health data generation failed: \(error.localizedDescription)")
            }
        }
    }
    
    func importFromJSON(_ jsonString: String) {
        guard !isGeneratingInProgress else { return }
        
        isGeneratingInProgress = true
        
        Task {
            do {
                let hkGenerator = HealthKitDataGenerator(healthStore: healthStore)
                
                // Validate first
                let isValid = try hkGenerator.validateLLMJSON(jsonString)
                guard isValid else {
                    throw NSError(domain: "HealthKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
                }
                
                // Import
                try hkGenerator.importFromLLMJSON(jsonString)
                
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                Self.logger.info("Successfully imported data from JSON")
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                Self.logger.error("JSON import failed: \(error.localizedDescription)")
            }
        }
    }
}
