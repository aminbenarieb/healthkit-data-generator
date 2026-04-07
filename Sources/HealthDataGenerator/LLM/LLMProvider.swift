import Foundation

// MARK: - LLM Provider Protocol

/// Protocol for LLM providers (Apple Foundation Model, OpenAI, etc.)
public protocol LLMProvider {
    /// Provider identifier
    var identifier: String { get }
    
    /// Provider name for display
    var name: String { get }
    
    /// Whether the provider is available on this device
    var isAvailable: Bool { get }
    
    /// Generate health data configuration from natural language
    /// - Parameter prompt: Natural language description
    /// - Returns: JSON string conforming to LLM schema
    func generateHealthConfig(from prompt: String) async throws -> String
    
    /// Validate if the provider can handle the request
    /// - Parameter prompt: Natural language description
    /// - Returns: True if provider can handle the request
    func canHandle(_ prompt: String) -> Bool
}

// MARK: - LLM Response

/// Response from LLM provider
public struct LLMResponse {
    public let provider: String
    public let json: String
    public let confidence: Double
    public let processingTime: TimeInterval
    
    public init(provider: String, json: String, confidence: Double, processingTime: TimeInterval) {
        self.provider = provider
        self.json = json
        self.confidence = confidence
        self.processingTime = processingTime
    }
}

// MARK: - LLM Error

/// Errors that can occur during LLM operations
public enum LLMError: Error, LocalizedError {
    case providerUnavailable(String)
    case invalidPrompt(String)
    case generationFailed(String)
    case invalidResponse(String)
    case networkError(String)
    case rateLimitExceeded
    case quotaExceeded
    
    public var errorDescription: String? {
        switch self {
        case .providerUnavailable(let provider):
            return "LLM provider '\(provider)' is not available"
        case .invalidPrompt(let reason):
            return "Invalid prompt: \(reason)"
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        case .invalidResponse(let reason):
            return "Invalid response: \(reason)"
        case .networkError(let reason):
            return "Network error: \(reason)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .quotaExceeded:
            return "Quota exceeded"
        }
    }
}
