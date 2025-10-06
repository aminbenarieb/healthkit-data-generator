import XCTest
@testable import HealthKitDataGenerator

// MARK: - Debug Output Tests

final class DebugOutputTests: XCTestCase {
    
    var llmManager: LLMManager!
    
    override func setUp() {
        super.setUp()
        llmManager = LLMManager()
    }
    
    override func tearDown() {
        llmManager = nil
        super.tearDown()
    }
    
    func testDebugMarathonPrompt() async throws {
        let prompt = "Create a 16-week marathon training program for an intermediate runner"
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        print("=== MARATHON PROMPT DEBUG ===")
        print("Prompt: \(prompt)")
        print("Response JSON:")
        print(response.json)
        print("=== END DEBUG ===")
        
        // Basic assertions
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
    }
    
    func testDebugWeightLossPrompt() async throws {
        let prompt = "Create a 12-week weight loss program for someone who wants to lose 20 pounds"
        
        let response = try await llmManager.generateHealthConfig(from: prompt)
        
        print("=== WEIGHT LOSS PROMPT DEBUG ===")
        print("Prompt: \(prompt)")
        print("Response JSON:")
        print(response.json)
        print("=== END DEBUG ===")
        
        // Basic assertions
        XCTAssertFalse(response.json.isEmpty)
        XCTAssertTrue(response.json.contains("schema_version"))
        XCTAssertTrue(response.json.contains("generation_config"))
    }
}
