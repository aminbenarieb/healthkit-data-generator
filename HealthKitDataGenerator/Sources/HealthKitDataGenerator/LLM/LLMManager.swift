import Foundation
import HealthKit
import Logging

// MARK: - LLM Manager

/// Manages multiple LLM providers and routes requests to the best available provider
public class LLMManager {
    
    private let logger = AppLogger.llm
    private var providers: [LLMProvider] = []
    
    public init() {
        setupProviders()
    }
    
    /// Register a new LLM provider
    /// - Parameter provider: LLM provider to register
    public func register(_ provider: LLMProvider) {
        providers.append(provider)
        logger.info("Registered LLM provider", metadata: ["provider": "\(provider.identifier)"])
    }
    
    /// Get all available providers
    /// - Returns: Array of available providers
    public func availableProviders() -> [LLMProvider] {
        return providers.filter { $0.isAvailable }
    }
    
    /// Generate health configuration from natural language
    /// - Parameter prompt: Natural language description
    /// - Returns: LLM response with JSON configuration
    public func generateHealthConfig(from prompt: String) async throws -> LLMResponse {
        logger.info("Generating health config from prompt", metadata: ["prompt": "\(prompt.prefix(100))..."])
        
        // Find the best provider for this request
        guard let provider = selectBestProvider(for: prompt) else {
            throw LLMError.providerUnavailable("No available providers")
        }
        
        let startTime = Date()
        
        do {
            let json = try await provider.generateHealthConfig(from: prompt)
            let processingTime = Date().timeIntervalSince(startTime)
            
            logger.info("Successfully generated config", metadata: [
                "provider": "\(provider.identifier)",
                "processingTime": "\(processingTime)",
                "responseLength": "\(json.count)"
            ])
            
            return LLMResponse(
                provider: provider.identifier,
                json: json,
                confidence: 0.8, // TODO: Implement confidence scoring
                processingTime: processingTime
            )
        } catch {
            logger.error("Failed to generate config", metadata: [
                "provider": "\(provider.identifier)",
                "error": "\(error.localizedDescription)"
            ])
            throw error
        }
    }
    
    /// Validate LLM-generated JSON
    /// - Parameter json: JSON string to validate
    /// - Returns: True if valid
    public func validateJSON(_ json: String) throws -> Bool {
        // Use existing validation logic
        let generator = HealthKitDataGenerator(healthStore: HKHealthStore())
        return try generator.validateLLMJSON(json)
    }
    
    // MARK: - Private Methods
    
    private func setupProviders() {
        // Register Apple Foundation Model provider
        let provider = AppleFoundationModelProvider()
        logger.debug("Setting up providers", metadata: [
            "provider": "\(provider.identifier)",
            "isAvailable": "\(provider.isAvailable)"
        ])
        register(provider)
        
        // TODO: Register other providers as they become available
        // register(OpenAIProvider())
        // register(AnthropicProvider())
    }
    
    private func selectBestProvider(for prompt: String) -> LLMProvider? {
        // Filter available providers that can handle the request
        let capableProviders = availableProviders().filter { $0.canHandle(prompt) }
        
        logger.debug("Available providers: \(availableProviders().count)", metadata: [
            "capableProviders": "\(capableProviders.count)",
            "prompt": "\(prompt.prefix(50))..."
        ])
        
        // For now, return the first available provider
        // TODO: Implement more sophisticated provider selection
        return capableProviders.first
    }
}
