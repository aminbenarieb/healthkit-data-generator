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
                // Mode Selector
                modeSelector
                
                // Content based on selected mode
                if selectedMode == .manual {
                    manualModeView
                } else {
                    llmModeView
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
            
            HStack(spacing: 12) {
                TextField("Describe the health data you want to generate...", text: $currentMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .disabled(isGenerating)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(currentMessage.isEmpty || isGenerating ? .gray : .blue)
                }
                .disabled(currentMessage.isEmpty || isGenerating)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Manual Mode Sections (Preserved from original)
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Generate Health Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create realistic health data for testing and development")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedProfile.id == profile.id ? Color.blue : Color.gray.opacity(0.2))
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
            .disabled(healthKitManager.isGenerating)
            
            if healthKitManager.isGenerating {
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
        case .lastDays: dateRange = .lastDays(Int(sampleCount))
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
            dateRange = .lastDays(Int(sampleCount)) // Placeholder, needs date picker
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
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.blue)
                        )
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.gray.opacity(0.1))
                        )
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Typing Indicator View

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.1))
            )
            Spacer(minLength: 50)
        }
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
