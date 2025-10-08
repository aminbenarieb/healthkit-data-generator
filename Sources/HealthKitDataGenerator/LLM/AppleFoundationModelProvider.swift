import Foundation
import Logging
#if canImport(FoundationModels)
import FoundationModels

// MARK: - Apple Foundation Model Provider

/// Apple Foundation Model provider implementation using the real FoundationModels framework
@available(iOS 26.0, macOS 26.0, *)
public class AppleFoundationModelProvider: LLMProvider {
    
    private let logger = AppLogger.llm
    private let languageModel: SystemLanguageModel
    private var session: LanguageModelSession?
    
    public let identifier = "apple_foundation_model"
    public let name = "Apple Foundation Model"
    
    public var isAvailable: Bool {
        switch languageModel.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
    
    public init() {
        self.languageModel = SystemLanguageModel.init(guardrails: Guardrails.developerProvided)
        logger.info("Initialized Apple Foundation Model provider", metadata: [
            "availability": "\(languageModel.availability)",
            "framework": "FoundationModels"
        ])
    }
    
    public func generateHealthConfig(from prompt: String) async throws -> String {
        logger.info("Generating config with Apple Foundation Model", metadata: ["prompt": "\(prompt.prefix(50))..."])
        
        return try await generateWithRealFoundationModel(prompt)
    }
    
    // MARK: - Real Foundation Model Implementation
    
    private func generateWithRealFoundationModel(_ prompt: String, attempt: Int = 1) async throws -> String {
        // Check if model is available
        guard isAvailable else {
            throw LLMError.providerUnavailable("Apple Foundation Model is not available on this device")
        }
        
        // Create session if needed
        if session == nil {
            session = LanguageModelSession(model: self.languageModel)
        }
        
        guard let session = session else {
            throw LLMError.generationFailed("Failed to create language model session")
        }
        
        // Create the health data generation prompt
        let systemPrompt = createSystemPrompt()
        let fullPrompt = "\(systemPrompt)\n\nUser Request: \(prompt)"
        
        do {
            // Generate response using Apple Foundation Model
            let response = try await session.respond(to: fullPrompt)
            
            logger.info("Successfully generated response", metadata: [
                "responseLength": "\(response.content.count)",
                "model": "Apple Foundation Model"
            ])
            
            // Extract JSON from response
            return try extractJSONFromResponse(response.content)
            
        } catch {
            if let genError = error as? LanguageModelSession.GenerationError {
                switch genError {
                case .exceededContextWindowSize(_):
                    if attempt > 1 {
                        break
                    }
                    logger.warning(("Exceeded context window size. Resetting session and retrying..."))
                    self.session = LanguageModelSession(model: self.languageModel) // reseting session
                    return try await generateWithRealFoundationModel(prompt, attempt: attempt + 1)
                default:
                    break
                }
            }
            logger.error("Failed to generate response", metadata: [
                "error": "\(error.localizedDescription)"
            ])
            throw error
        }
    }
    
    public func canHandle(_ prompt: String) -> Bool {
        return true
//        // Apple Foundation Model can handle most health-related prompts
//        let healthKeywords = ["health", "fitness", "exercise", "workout", "sleep", "heart", "steps", "calories", "training", "recovery", "weight"]
//        return healthKeywords.contains { keyword in
//            prompt.lowercased().contains(keyword)
//        }
    }
    
    // MARK: - Private Methods
    
    private func createSystemPrompt() -> String {
        return """
        Generate health data JSON from natural language. Calculate dates relative to TODAY.

        JSON Schema:
        {
          "schema_version": "1.0",
          "generation_config": {
            "profile": {
              "id": "unique_string",
              "name": "Profile Name", 
              "description": "Profile description",
              "dailyStepsRange": [min_steps, max_steps],
              "workoutFrequency": "sedentary|light|moderate|active|athlete",
              "preferredWorkoutTypes": ["running", "yoga"],
              "sleepDurationRange": [min_hours, max_hours],
              "sleepQuality": "poor|fair|good|excellent",
              "bedtimeRange": [start_hour, end_hour],
              "restingHeartRateRange": [min_bpm, max_bpm],
              "maxHeartRateRange": [min_bpm, max_bpm],
              "heartRateVariability": "low|moderate|high",
              "basalEnergyMultiplier": decimal_number,
              "activeEnergyRange": [min_calories, max_calories],
              "stressLevel": "low|moderate|high|very_high",
              "recoveryRate": "slow|average|fast",
              "dietaryPattern": "standard|vegetarian|vegan|keto|mediterranean|high_protein",
              "hydrationLevel": "low|moderate|high"
            },
            "dateRange": {
              "startDate": "YYYY-MM-DDTHH:mm:ss.sssZ",
              "endDate": "YYYY-MM-DDTHH:mm:ss.sssZ"
            },
            "metricsToGenerate": ["steps", "heart_rate", "workouts", "sleep_analysis", "active_energy", "basal_energy"],
            "pattern": "continuous|sparse|weekdays_only|weekends_only",
            "randomSeed": integer_number
          }
        }

        Field Explanations:
        - dailyStepsRange: [Int, Int] - steps per day (e.g., [5000, 12000])
        - workoutFrequency: String - "sedentary"|"light"|"moderate"|"active"|"athlete"
        - preferredWorkoutTypes: [String] - ["running", "yoga", "cycling", "swimming", "strength_training", "walking", "dancing", "hiking", "basketball", "tennis"]
        - sleepDurationRange: [Double, Double] - hours per night (e.g., [6.5, 8.5])
        - sleepQuality: String - "poor"|"fair"|"good"|"excellent"
        - bedtimeRange: [Int, Int] - hour when they go to bed (0-23, e.g., [22, 24])
        - restingHeartRateRange: [Int, Int] - bpm (e.g., [60, 80])
        - maxHeartRateRange: [Int, Int] - bpm (e.g., [180, 200])
        - heartRateVariability: String - "low"|"moderate"|"high"
        - basalEnergyMultiplier: Double - metabolism multiplier (0.5-1.5)
        - activeEnergyRange: [Int, Int] - calories burned through activity (e.g., [200, 800])
        - stressLevel: String - "low"|"moderate"|"high"|"very_high"
        - recoveryRate: String - "slow"|"average"|"fast"
        - dietaryPattern: String - "standard"|"vegetarian"|"vegan"|"keto"|"mediterranean"|"high_protein"
        - hydrationLevel: String - "low"|"moderate"|"high"

        Profile Examples:
        - Sedentary: steps[2000-5000], sleep[6-8h], hr[70-85], energy[100-300], stress[high]
        - Active: steps[8000-12000], sleep[7-8.5h], hr[60-75], energy[400-800], stress[moderate]  
        - Athlete: steps[15000-30000], sleep[8-10h], hr[45-60], energy[800-2000], stress[low]

        Rules:
        - Use \(Date().formatted(.iso8601)) as endDate, calculate startDate by subtracting days. 
        - NEVER ADD DATA AFTER endDate
        - All ranges are arrays [min, max]
        - Respond with ONLY JSON, no explanation
        - DO NOT USE VALUES OUTSIDE OF PROVIDED
        """
    }
    
    private func extractJSONFromResponse(_ response: String) throws -> String {
        // Try to find JSON in the response
        let jsonPattern = #"\{[\s\S]*\}"#
        let regex = try NSRegularExpression(pattern: jsonPattern)
        let range = NSRange(location: 0, length: response.utf16.count)
        
        if let match = regex.firstMatch(in: response, options: [], range: range) {
            let jsonString = String(response[Range(match.range, in: response)!])
            
            // Validate that it's valid JSON
            do {
                let smt = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
                return jsonString
            } catch {
                throw LLMError.invalidResponse("Failed to get json from LLM response \(error.localizedDescription)")
            }
        }
        
        // If no valid JSON found, throw error
        throw LLMError.invalidResponse("No valid JSON found in response")
    }
    
}

@available(iOS 26.0, macOS 26, *)
struct Guardrails {
    static var developerProvided: SystemLanguageModel.Guardrails {
        var guardrails = SystemLanguageModel.Guardrails.default
        
        #if DEBUG
        withUnsafeMutablePointer(to: &guardrails) { ptr in
            let rawPtr = UnsafeMutableRawPointer(ptr)
            let boolPtr = rawPtr.assumingMemoryBound(to: Bool.self)
            boolPtr.pointee = false
        }
        #endif
        
        return guardrails
    }
}

#else
public class AppleFoundationModelProvider: LLMProvider {
    
    public let identifier = "apple_foundation_model"
    public let name = "Apple Foundation Model"
    public var isAvailable: Bool = false
    public func canHandle(_ prompt: String) -> Bool { false }

    public func generateHealthConfig(from prompt: String) async throws -> String {
        throw LLMError.providerUnavailable("Apple Foundation Model is not available on this OS")
    }
    
}
#endif
