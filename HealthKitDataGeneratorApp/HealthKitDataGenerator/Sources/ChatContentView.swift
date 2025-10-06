import SwiftUI
import HealthKit
import HealthKitDataGenerator

// MARK: - Generation Mode

enum GenerationMode: String, CaseIterable {
    case manual = "manual"
    case llm = "llm"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .llm: return "AI Chat"
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "slider.horizontal.3"
        case .llm: return "message.circle"
        }
    }
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

// MARK: - Chat Content View

public struct ChatContentView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedMode: GenerationMode = .manual
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // LLM Availability
    @State private var llmManager = LLMManager()
    @State private var hasAvailableProviders = false
    
    // Manual Mode State
    @State private var sampleCount: UInt = 7
    @State private var selectedProfile: HealthProfile = .balanced
    @State private var selectedDateRangeType: DateRangeType = .lastDays
    @State private var selectedPattern: GenerationPattern = .continuous
    @State private var selectedAdvancedPattern: AdvancedPattern = .sparseCustom
    @State private var sparseProbability: Double = 0.7
    @State private var showingAdvancedOptions = false
    @State private var selectedMetrics: Set<HealthMetric> = Set(HealthMetric.allCases)
    @State private var showingMetricCustomization = false
    
    // LLM Mode State
    @State private var chatMessages: [ChatMessage] = []
    @State private var currentMessage = ""
    @State private var isGenerating = false
    @State private var showingJSONImport = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Selector (only show if AI providers are available)
                if hasAvailableProviders {
                    modeSelector
                }
                
                // Content based on selected mode
                if selectedMode == .manual {
                    manualModeView
                } else if hasAvailableProviders {
                    llmModeView
                } else {
                    // Show AI unavailable message in manual mode
                    aiUnavailableView
                }
            }
            .navigationTitle("HealthKit Data Generator")
            .navigationBarTitleDisplayMode(.large)
            .alert("Alert", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingJSONImport) {
                JSONImportView()
            }
            .onAppear {
                checkProviderAvailability()
            }
            .task {
                if HKHealthStore.isHealthDataAvailable() && !healthKitManager.isAuthorized {
                    await healthKitManager.requestAuthorization()
                }
            }
        }
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(GenerationMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedMode = mode
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(mode.displayName)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(selectedMode == mode ? .white : .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == mode ? Color.blue : Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Manual Mode View
    
    private var manualModeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Authorization Status
                authorizationSection
                
                // Profile Selection
                profileSection
                
                // Date Range Selection
                dateRangeSection
                
                // Generation Pattern
                patternSection
                
                // Advanced Options
                advancedOptionsSection
                
                // Metrics Selection
                metricsSection
                
                // Generate Button
                generateButton
                
                // Clean Data Button
                cleanDataButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - LLM Mode View
    
    private var llmModeView: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if chatMessages.isEmpty {
                            welcomeMessage
                        } else {
                            ForEach(chatMessages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                        }
                        
                        if isGenerating {
                            TypingIndicatorView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: chatMessages.count) { _ in
                    if let lastMessage = chatMessages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Chat Input
            chatInputSection
            
            // Clean Data Button (for LLM mode)
            if !chatMessages.isEmpty {
                VStack(spacing: 12) {
                    Divider()
                    cleanDataButton
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
        }
    }
    
    // MARK: - Welcome Message
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("AI Health Data Generator")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Describe what kind of health data you want to generate, and I'll create a personalized configuration for you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Try saying:")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("• \"Generate 2 weeks of marathon training data\"")
                Text("• \"Create recovery data for an injured athlete\"")
                Text("• \"Make weight loss progress data for 30 days\"")
                Text("• \"Generate stress management data for an executive\"")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Chat Input Section
    
    private var chatInputSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 12) {
                    // Text input with enhanced styling
                    VStack(spacing: 0) {
                        TextField("Describe the health data you want to generate...", text: $currentMessage, axis: .vertical)
                            .font(.system(size: 16, weight: .regular))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                currentMessage.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5),
                                                lineWidth: currentMessage.isEmpty ? 1 : 2
                                            )
                                    )
                            )
                            .lineLimit(1...6)
                            .disabled(isGenerating)
                            .animation(.easeInOut(duration: 0.2), value: currentMessage.isEmpty)
                        
                        // Character count (optional)
                        if !currentMessage.isEmpty {
                            HStack {
                                Spacer()
                                Text("\(currentMessage.count) characters")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 16)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Send button with enhanced styling
                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(currentMessage.isEmpty || isGenerating ? Color.gray.opacity(0.3) : Color.blue)
                                .frame(width: 44, height: 44)
                            
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(currentMessage.isEmpty || isGenerating)
                    .scaleEffect(currentMessage.isEmpty ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentMessage.isEmpty)
                }
                
                // Quick action buttons
                if currentMessage.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(quickActions, id: \.self) { action in
                            Button(action: {
                                currentMessage = action
                            }) {
                                Text(action)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: -1)
            )
        }
    }
    
    private var quickActions: [String] {
        [
            "Generate 2 weeks of marathon training data",
            "Create recovery data for an injured athlete",
            "Make weight loss progress data for 30 days"
        ]
    }
    
    // MARK: - Manual Mode Sections (Preserved from original)
    
    private var authorizationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: healthKitManager.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(healthKitManager.isAuthorized ? .green : .orange)
                
                Text(healthKitManager.isAuthorized ? "HealthKit Authorized" : "HealthKit Authorization Required")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            
            if !healthKitManager.isAuthorized {
                Button(action: {
                    Task {
                        await healthKitManager.requestAuthorization()
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.text.square")
                        Text("Request HealthKit Permission")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Generate Health Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create realistic health data for testing and development")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if hasAvailableProviders {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                    Text("AI Chat mode also available")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Profile")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HealthProfile.allPresets, id: \.id) { profile in
                        Button(action: { selectedProfile = profile }) {
                            VStack(spacing: 4) {
                                Text(profile.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(profile.description)
                                    .font(.caption2)
                                    .foregroundColor(selectedProfile.id == profile.id ? .white.opacity(0.8) : .secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedProfile.id == profile.id ? Color.blue : Color.gray.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedProfile.id == profile.id ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            )
                            .foregroundColor(selectedProfile.id == profile.id ? .white : .primary)
                        }
                        .frame(width: 120)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateRangeType.allCases, id: \.self) { type in
                        Button(action: { selectedDateRangeType = type }) {
                            Text(type.displayName)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedDateRangeType == type ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .foregroundColor(selectedDateRangeType == type ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if selectedDateRangeType == .lastDays {
                HStack {
                    Text("Number of Days:")
                        .font(.subheadline)
                    Spacer()
                    Stepper(value: $sampleCount, in: 1...90) {
                        Text("\(sampleCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generation Pattern")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GenerationPattern.allCases, id: \.self) { pattern in
                        Button(action: { selectedPattern = pattern }) {
                            Text(pattern.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedPattern == pattern ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .foregroundColor(selectedPattern == pattern ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { showingAdvancedOptions.toggle() }) {
                HStack {
                    Text("Advanced Options")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .foregroundColor(.primary)
            
            if showingAdvancedOptions {
                VStack(spacing: 12) {
                    HStack {
                        Text("Sparse Probability:")
                            .font(.subheadline)
                        Spacer()
                        Slider(value: $sparseProbability, in: 0.1...1.0, step: 0.1) {
                            Text("Probability")
                        }
                        Text("\(Int(sparseProbability * 100))%")
                            .font(.caption)
                            .frame(width: 30)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Metrics to Generate")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Customize") {
                    showingMetricCustomization = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Text("\(selectedMetrics.count) metrics selected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingMetricCustomization) {
            MetricCustomizationView(selectedMetrics: $selectedMetrics)
        }
    }
    
    private var generateButton: some View {
        VStack(spacing: 12) {
            Button(action: generateHealthDataWithEnhancedConfig) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Generate Health Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            .disabled(healthKitManager.isGeneratingInProgress)
            
            if healthKitManager.isGeneratingInProgress {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating health data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var cleanDataButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                healthKitManager.cleanHealthData()
            }) {
                HStack {
                    if healthKitManager.isCleaningInProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 18))
                    }
                    Text(healthKitManager.isCleaningInProgress ? "Cleaning..." : "Clean Health Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(healthKitManager.isCleaningInProgress ? Color.gray : Color.red)
                )
            }
            .disabled(healthKitManager.isCleaningInProgress)
            
            // Cleaning Progress
            if healthKitManager.isCleaningInProgress {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cleaning Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let progress = healthKitManager.cleaningProgress {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    } else {
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    
                    Text(healthKitManager.cleaningMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Provider Availability
    
    private func checkProviderAvailability() {
        let availableProviders = llmManager.availableProviders()
        hasAvailableProviders = !availableProviders.isEmpty
        
        // If no AI providers available, ensure we're in manual mode
        if !hasAvailableProviders {
            selectedMode = .manual
        }
    }
    
    // MARK: - AI Unavailable View
    
    private var aiUnavailableView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile.slash")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)
                
                Text("AI Chat Unavailable")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("AI-powered health data generation is not available on this device. This feature requires iOS 18+ with Apple Intelligence support.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Manual generation is fully available")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All health profiles and patterns work")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Clean data functionality included")
                            .font(.subheadline)
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Chat Functions
    
    private func sendMessage() {
        guard !currentMessage.isEmpty else { return }
        
        let userMessage = ChatMessage(content: currentMessage, isUser: true)
        chatMessages.append(userMessage)
        
        let message = currentMessage
        currentMessage = ""
        isGenerating = true
        
        Task {
            do {
                let response = try await healthKitManager.generateWithLLM(prompt: message)
                
                await MainActor.run {
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    chatMessages.append(aiMessage)
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(content: "Sorry, I couldn't process your request. Please try again.", isUser: false)
                    chatMessages.append(errorMessage)
                    isGenerating = false
                }
            }
        }
    }
    
    // MARK: - Manual Generation Functions
    
    private func generateHealthDataWithEnhancedConfig() {
        let dateRange: DateRange
        switch selectedDateRangeType {
        case .lastDays: dateRange = .lastDays(sampleCount)
        case .thisWeek: dateRange = .thisWeek()
        case .thisMonth: dateRange = .thisMonth()
        case .weekdaysOnly:
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -Int(sampleCount), to: endDate) ?? endDate
            dateRange = .weekdaysOnly(start: startDate, end: endDate)
        case .weekendsOnly:
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -Int(sampleCount), to: endDate) ?? endDate
            dateRange = .weekendsOnly(start: startDate, end: endDate)
        case .specificDates:
            dateRange = .lastDays(sampleCount) // Placeholder, needs date picker
        }
        
        let config = SampleGenerationConfig(
            profile: selectedProfile,
            dateRange: dateRange,
            metricsToGenerate: selectedMetrics,
            pattern: selectedPattern,
            randomSeed: nil,
            customOverrides: nil // TODO: Add UI for custom overrides
        )
        healthKitManager.generateHealthData(config: config)
    }
}

// MARK: - Chat Message View

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 6) {
                    Text(message.content)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        // AI avatar
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            )
                        
                        Text(message.content)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 40)
                }
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Typing Indicator View

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    // AI avatar
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        )
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .offset(y: animationOffset)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: animationOffset
                                )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 4)
        .onAppear {
            animationOffset = -4
        }
    }
}

// MARK: - Metric Customization View

struct MetricCustomizationView: View {
    @Binding var selectedMetrics: Set<HealthMetric>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Select Metrics to Generate") {
                    ForEach(HealthMetric.allCases, id: \.self) { metric in
                        HStack {
                            Text(metric.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.subheadline)
                            Spacer()
                            if selectedMetrics.contains(metric) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedMetrics.contains(metric) {
                                selectedMetrics.remove(metric)
                            } else {
                                selectedMetrics.insert(metric)
                            }
                        }
                    }
                }
                Section {
                    HStack {
                        Button("Select All") { selectedMetrics = Set(HealthMetric.allCases) }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button("Select None") { selectedMetrics.removeAll() }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Customize Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.fontWeight(.semibold) }
            }
        }
    }
}

// MARK: - JSON Import View

struct JSONImportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var jsonText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Import from JSON")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Paste your JSON configuration below:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $jsonText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("JSON Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        importJSON()
                    }
                    .disabled(jsonText.isEmpty)
                }
            }
            .alert("Import Result", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func importJSON() {
        // TODO: Implement JSON import functionality
        alertMessage = "JSON import functionality will be implemented"
        showingAlert = true
    }
}
