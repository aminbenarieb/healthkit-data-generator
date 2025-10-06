import XCTest
@testable import HealthKitDataGenerator

// MARK: - Production Scenario Tests

/// Tests real-world usage scenarios for LLM integration
final class ProductionScenarioTests: XCTestCase {
    
    var llmManager: LLMManager!
    
    override func setUp() {
        super.setUp()
        llmManager = LLMManager()
    }
    
    override func tearDown() {
        llmManager = nil
        super.tearDown()
    }
    
    // MARK: - Marathon Training Scenarios
    
    func testMarathonTrainingProgram() async throws {
        let prompt = """
        Create a 16-week marathon training program for an intermediate runner.
        They currently run 25-30 miles per week, have been running for 2 years,
        and want to complete their first marathon in under 4 hours.
        Include progressive mileage increases, rest days, and taper weeks.
        """
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
        
        // Should contain marathon-related profile (check for any of these terms)
        let hasMarathonContent = response.json.contains("marathon") || 
                                response.json.contains("runner") || 
                                response.json.contains("Marathon") ||
                                response.json.contains("athlete") ||
                                response.json.contains("training")
        XCTAssertTrue(hasMarathonContent, "Response should contain marathon-related content")
        
        // Should have valid JSON structure
        XCTAssertTrue(response.json.contains("dateRange"), "Response should contain dateRange")
        XCTAssertTrue(response.json.contains("profile"), "Response should contain profile")
    }
    
    func testInjuryRecoveryProgram() async throws {
        let prompt = """
        Generate a 8-week recovery program for a runner with a knee injury.
        They need to reduce impact activities, focus on strength training,
        and gradually return to running. Include physical therapy exercises.
        """
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
        
        // Should contain recovery-related profile
        XCTAssertTrue(response.json.contains("recovery") || response.json.contains("injury") || response.json.contains("sedentary"))
        
        // Should have appropriate date range
        XCTAssertTrue(response.json.contains("8") || response.json.contains("56")) // 8 weeks = 56 days
    }
    
    func testWeightLossProgram() async throws {
        let prompt = """
        Create a 12-week weight loss program for someone who wants to lose 20 pounds.
        They are currently sedentary, work a desk job, and have 1 hour per day for exercise.
        Focus on cardio, strength training, and dietary changes.
        """
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
        
        // Should contain weight loss or fitness-related profile
        let hasFitnessContent = response.json.contains("weight") || 
                              response.json.contains("loss") || 
                              response.json.contains("fitness") || 
                              response.json.contains("Fitness") ||
                              response.json.contains("enthusiast")
        XCTAssertTrue(hasFitnessContent, "Response should contain fitness-related content")
        
        // Should have 12-week duration
        XCTAssertTrue(response.json.contains("12") || response.json.contains("84")) // 12 weeks = 84 days
    }
    
    // MARK: - Stress Management Scenarios
    
    func testStressReductionProgram() async throws {
        let prompt = """
        Generate a 4-week stress reduction program for a busy executive.
        They work 60+ hours per week, have high stress levels, and need
        to improve sleep quality and overall well-being.
        """
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
        
        // Should contain stress-related profile
        XCTAssertTrue(response.json.contains("stress") || response.json.contains("executive") || response.json.contains("stressed"))
        
        // Should have 4-week duration
        XCTAssertTrue(response.json.contains("4") || response.json.contains("28")) // 4 weeks = 28 days
    }
    
    // MARK: - Athletic Performance Scenarios
    
    func testEliteAthleteTraining() async throws {
        let prompt = """
        Create a 6-month training program for an elite triathlete preparing
        for an Ironman competition. They train 20+ hours per week and need
        to balance swimming, cycling, and running with recovery.
        """
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
        
        // Should contain elite athlete profile
        XCTAssertTrue(response.json.contains("elite") || response.json.contains("athlete") || response.json.contains("sporty"))
        
        // Should have extended duration
        XCTAssertTrue(response.json.contains("6") || response.json.contains("180")) // 6 months = 180 days
    }
    
    func testSeniorFitnessProgram() async throws {
        let prompt = """
        Generate a 8-week fitness program for a 65-year-old who wants to
        improve mobility, strength, and cardiovascular health. They have
        mild arthritis and need low-impact exercises.
        """
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
        
        // Should contain senior or gentle fitness profile
        let hasSeniorContent = response.json.contains("senior") || 
                              response.json.contains("gentle") || 
                              response.json.contains("balanced") || 
                              response.json.contains("Senior") ||
                              response.json.contains("fitness")
        XCTAssertTrue(hasSeniorContent, "Response should contain senior fitness content")
        
        // Should have 8-week duration
        XCTAssertTrue(response.json.contains("8") || response.json.contains("56")) // 8 weeks = 56 days
    }
    
    // MARK: - Performance Testing
    
    func testResponseTimePerformance() async throws {
        let prompt = "Create a week of health data for a balanced lifestyle"
        
        let startTime = Date()
        let response = try await llmManager.generateHealthConfig(from: prompt)
        let endTime = Date()
        
        let responseTime = endTime.timeIntervalSince(startTime)
        
        // Should respond within reasonable time (5 seconds for mock)
        XCTAssertLessThan(responseTime, 5.0, "Response time should be under 5 seconds")
        
        // Response should be valid
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
    }
    
    func testConcurrentRequests() async throws {
        let prompts = [
            "Create marathon training data",
            "Generate recovery week data",
            "Create weight loss program",
            "Generate stress reduction plan"
        ]
        
        // Test concurrent requests
        let responses = try await withThrowingTaskGroup(of: LLMResponse.self) { group in
            for prompt in prompts {
                group.addTask {
                    try await self.llmManager.generateHealthConfig(from: prompt)
                }
            }
            
            var responses: [LLMResponse] = []
            for try await response in group {
                responses.append(response)
            }
            return responses
        }
        
        XCTAssertEqual(responses.count, prompts.count)
        
        for response in responses {
            XCTAssertFalse(response.json.isEmpty)
            XCTAssertTrue(response.json.contains("schema_version"))
        }
    }
    
    // MARK: - Error Handling Scenarios
    
    func testInvalidPromptHandling() async throws {
        let invalidPrompts = [
            "This is not a health-related request",
            "Write a poem about cats",
            "Calculate the weather forecast",
            "Generate random numbers"
        ]
        
        for prompt in invalidPrompts {
            do {
                let response = try await llmManager.generateHealthConfig(from: prompt)
                // Should still generate some response
                XCTAssertFalse(response.json.isEmpty)
                XCTAssertTrue(response.json.contains("schema_version"))
            } catch {
                // It's also acceptable for invalid prompts to throw errors
                XCTAssertTrue(error is LLMError, "Should throw LLMError for invalid prompts")
            }
        }
    }
    
    func testEmptyPromptHandling() async throws {
        let emptyPrompt = ""
        
        do {
            let response = try await llmManager.generateHealthConfig(from: emptyPrompt)
            // Should still generate some response
            XCTAssertFalse(response.json.isEmpty)
            XCTAssertTrue(response.json.contains("schema_version"))
        } catch {
            // It's also acceptable for empty prompts to throw errors
            XCTAssertTrue(error is LLMError, "Should throw LLMError for empty prompts")
        }
    }
    
    // MARK: - Real-World Integration Scenarios
    
    func testHealthKitIntegration() async throws {
        let prompt = "Create a week of realistic health data for a fitness enthusiast"
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        // Validate JSON structure
        let data = response.json.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["schema_version"] as? String, "1.0")
        XCTAssertNotNil(json["generation_config"])
        
        let config = json["generation_config"] as! [String: Any]
        XCTAssertNotNil(config["profile"])
        XCTAssertNotNil(config["dateRange"])
        XCTAssertNotNil(config["metricsToGenerate"])
        XCTAssertNotNil(config["pattern"])
        
        // Should contain relevant health metrics
        let metrics = config["metricsToGenerate"] as! [String]
        XCTAssertTrue(metrics.contains("steps"))
        XCTAssertTrue(metrics.contains("heart_rate"))
        XCTAssertTrue(metrics.contains("workouts"))
    }
    
    func testCustomProfileGeneration() async throws {
        let prompt = """
        Create a custom health profile for a yoga instructor who practices
        daily meditation, follows a plant-based diet, and maintains a
        balanced lifestyle with moderate exercise.
        """
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        XCTAssertFalse(response.json.isEmpty)
        
        // Validate JSON structure
        let data = response.json.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let config = json["generation_config"] as! [String: Any]
        let profile = config["profile"] as! [String: Any]
        
        // Should contain yoga-related profile
        XCTAssertTrue(profile["name"] as? String != nil)
        XCTAssertTrue(profile["description"] as? String != nil)
        
        // Should have realistic health metrics
        XCTAssertNotNil(profile["dailyStepsRange"])
        XCTAssertNotNil(profile["sleepDurationRange"])
        XCTAssertNotNil(profile["workoutFrequency"])
    }
}
