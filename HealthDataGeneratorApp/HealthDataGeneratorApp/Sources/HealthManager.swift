import HealthKit
import HealthDataGenerator
import Logging

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    private let logger = AppUILogger.userAction
    private let authLogger = AppUILogger.authorization
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var isCleaningInProgress = false
    @Published var isGeneratingInProgress = false
    @Published var cleaningMessage = ""
    @Published var cleaningProgress: Double? = nil
    @Published var generationResult: GenerationResult? = nil

    enum GenerationResult: Identifiable {
        case success(String)
        case failure(String)

        var id: String {
            switch self {
            case .success(let msg): return "success-\(msg)"
            case .failure(let msg): return "failure-\(msg)"
            }
        }
    }
    
    // LLM Integration
    private let llmManager = LLMManager()
    
    private init() {}
    
    func requestAuthorization() async {
        authLogger.info("Requesting Health authorization")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            authLogger.error("Health data is not available on this device")
            return
        }
        
        let readTypes = HealthConstants.authorizationReadTypes()
        let writeTypes = HealthConstants.authorizationWriteTypes()
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run { [weak self] in
                self?.isAuthorized = true
            }
            authLogger.info("✅ Health authorization granted", metadata: [
                "readTypes": "\(readTypes.count)",
                "writeTypes": "\(writeTypes.count)"
            ])
        } catch {
            authLogger.error("❌ Health authorization failed", metadata: [
                "error": "\(error.localizedDescription)"
            ])
        }
    }
    
    func cleanHealthData() {
        guard !isCleaningInProgress else { return }
        
        logger.info("🧹 Starting Health data cleanup")
        
        isCleaningInProgress = true
        cleaningMessage = "Starting cleanup..."
        cleaningProgress = nil
        
        Task {
            HealthStoreCleaner(healthStore: healthStore).clean { (message: String, progress) in
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

        guard isAuthorized else {
            logger.warning("Health not authorized, cannot generate data")
            generationResult = .failure("Health permission is required. Please authorize Health access first.")
            return
        }

        logger.info("🎯 User initiated generation", metadata: [
            "days": "\(count)",
            "profile": "\(profile.name)"
        ])

        isGeneratingInProgress = true

        Task {
            do {
                let hkGenerator = HealthDataGenerator(healthStore: healthStore)
                let shareTypes = HealthConstants.authorizationWriteTypes()

                // Create configuration with selected profile
                let config = SampleGenerationConfig(
                    profile: profile,
                    dateRange: .lastDays(count)
                )

                // Generate all samples with config
                try hkGenerator.generateAndPopulate(samplesTypes: shareTypes, config: config)

                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                    self?.generationResult = .success("Health data generated successfully for \(count) days using the \(profile.name) profile.")
                }
                logger.info("✅ Health data generation completed", metadata: [
                    "days": "\(count)",
                    "profile": "\(profile.name)"
                ])
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                    self?.generationResult = .failure("Failed to generate health data: \(error.localizedDescription)")
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

        guard isAuthorized else {
            logger.warning("Health not authorized, cannot generate data")
            generationResult = .failure("Health permission is required. Please authorize Health access first.")
            return
        }

        logger.info("🎯 User initiated custom config generation", metadata: [
            "profile": "\(config.profile.name)",
            "days": "\(config.dateRange.numberOfDays)"
        ])

        isGeneratingInProgress = true

        Task {
            do {
                let hkGenerator = HealthDataGenerator(healthStore: healthStore)
                let shareTypes = HealthConstants.authorizationWriteTypes()

                try hkGenerator.generateAndPopulate(samplesTypes: shareTypes, config: config)

                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                    self?.generationResult = .success("Health data generated successfully for \(config.dateRange.numberOfDays) days using the \(config.profile.name) profile.")
                }
                logger.info("✅ Custom config generation completed")
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                    self?.generationResult = .failure("Failed to generate health data: \(error.localizedDescription)")
                }
                logger.error("❌ Custom config generation failed", metadata: [
                    "error": "\(error.localizedDescription)"
                ])
            }
        }
    }
    
    // MARK: - LLM Integration
    
    func generateWithLLM(prompt: String) async throws -> String {
        logger.info("Generating health data with LLM", metadata: ["prompt": "\(prompt.prefix(50))..."])
        
        do {
            let response = try await llmManager.generateHealthConfig(from: prompt)
            let responseConfig = response.json
            
            // Validate the generated JSON
            let isValid = try llmManager.validateJSON(responseConfig)
            guard isValid else {
                throw NSError(domain: "HealthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON generated by LLM"])
            }
            
            // Generate and populate health data
            let hkGenerator = HealthDataGenerator(healthStore: healthStore)
            try hkGenerator.importFromLLMJSON(responseConfig)
            
            logger.info("✅ Successfully generated and populated health data with LLM")
            return "Health data generated successfully! I've created a personalized configuration based on your request and populated your Apple Health with the generated data."
            
        } catch {
            logger.error("❌ LLM generation failed", metadata: [
                "error": "\(error.localizedDescription)"
            ])
            throw error
        }
    }
}
