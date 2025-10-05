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
    
    func generateHealthData(count: Int) {
        guard !isGeneratingInProgress else { return }
        
        isGeneratingInProgress = true
        
        Task {
            do {
                let hkGenerator = HealthKitDataGenerator(healthStore: healthStore)
                let shareTypes = HealthKitConstants.authorizationWriteTypes()
                
                // Generate all samples with all data types included
                try hkGenerator.generateAndPopulate(samplesTypes: shareTypes, numberOfDays: count, includeBasalCalories: true)
                
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                Self.logger.info("Health data generation completed with \(count) days")
            } catch {
                await MainActor.run { [weak self] in
                    self?.isGeneratingInProgress = false
                }
                Self.logger.error("Health data generation failed: \(error.localizedDescription)")
            }
        }
    }
}
