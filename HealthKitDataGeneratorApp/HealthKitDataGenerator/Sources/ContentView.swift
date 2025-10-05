import SwiftUI
import HealthKit
import HealthKitDataGenerator

// MARK: - Date Range Type for UI

enum DateRangeType: String, CaseIterable {
    case lastDays = "last_days"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case weekdaysOnly = "weekdays_only"
    case weekendsOnly = "weekends_only"
    case specificDates = "specific_dates"
    
    var displayName: String {
        switch self {
        case .lastDays: return "Last N Days"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .weekdaysOnly: return "Weekdays"
        case .weekendsOnly: return "Weekends"
        case .specificDates: return "Specific"
        }
    }
}

public struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var sampleCount: UInt = 7
    @State private var selectedProfile: HealthProfile = .balanced
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingJSONImport = false
    
    // Enhanced UI State
    @State private var selectedDateRangeType: DateRangeType = .lastDays
    @State private var selectedPattern: GenerationPattern = .continuous
    @State private var selectedAdvancedPattern: AdvancedPattern = .sparseCustom
    @State private var sparseProbability: Double = 0.7
    @State private var showingAdvancedOptions = false
    @State private var selectedMetrics: Set<HealthMetric> = Set(HealthMetric.allCases)
    @State private var showingMetricCustomization = false
    
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red.gradient)
                    
                    Text("Health Data Generator")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text("Generate and manage sample health data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Main Controls
                VStack(spacing: 20) {
                    // Authorization Status
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
                    
                    if healthKitManager.isAuthorized {
                        // Profile Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Health Profile")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(HealthProfile.allPresets, id: \.id) { profile in
                                        Button(action: {
                                            selectedProfile = profile
                                        }) {
                                            Text(profile.name)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    selectedProfile.id == profile.id 
                                                    ? Color.blue 
                                                    : Color.gray.opacity(0.2)
                                                )
                                                .foregroundColor(
                                                    selectedProfile.id == profile.id 
                                                    ? .white 
                                                    : .primary
                                                )
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            Text(selectedProfile.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        
                        // Date Range Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date Range")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(DateRangeType.allCases, id: \.self) { type in
                                        Button(action: {
                                            selectedDateRangeType = type
                                        }) {
                                            Text(type.displayName)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    selectedDateRangeType == type 
                                                    ? Color.blue 
                                                    : Color.gray.opacity(0.2)
                                                )
                                                .foregroundColor(
                                                    selectedDateRangeType == type 
                                                    ? .white 
                                                    : .primary
                                                )
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            if selectedDateRangeType == .lastDays {
                                HStack {
                                    Text("Days:")
                                        .font(.subheadline)
                                    
                                    TextField("Days", value: $sampleCount, format: .number)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    
                                    Stepper("", value: $sampleCount, in: 1...90, step: 1)
                                    
                                    Spacer()
                                }
                                
                                Text("Generate data for the last \(sampleCount) day\(sampleCount == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(selectedDateRangeType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        
                        // Generation Pattern Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Generation Pattern")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach([GenerationPattern.continuous, .sparse, .weekdaysOnly, .weekendsOnly], id: \.self) { pattern in
                                        Button(action: {
                                            selectedPattern = pattern
                                        }) {
                                            Text(pattern.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    selectedPattern == pattern 
                                                    ? Color.blue 
                                                    : Color.gray.opacity(0.2)
                                                )
                                                .foregroundColor(
                                                    selectedPattern == pattern 
                                                    ? .white 
                                                    : .primary
                                                )
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            if selectedPattern == .sparse {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sparse Probability: \(Int(sparseProbability * 100))%")
                                        .font(.subheadline)
                                    
                                    Slider(value: $sparseProbability, in: 0.1...1.0, step: 0.1)
                                        .accentColor(.blue)
                                }
                            }
                            
                            Text(selectedPattern.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        
                        // Advanced Options Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Advanced Options")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingAdvancedOptions.toggle()
                                    }
                                }) {
                                    Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if showingAdvancedOptions {
                                VStack(spacing: 12) {
                                    // Advanced Pattern Selection
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Advanced Pattern")
                                            .font(.subheadline)
                                        
                                        Picker("Advanced Pattern", selection: $selectedAdvancedPattern) {
                                            Text("Sparse Custom").tag(AdvancedPattern.sparseCustom)
                                            Text("Seasonal").tag(AdvancedPattern.seasonal)
                                            Text("Progressive").tag(AdvancedPattern.progressive)
                                            Text("Every Nth Day").tag(AdvancedPattern.everyNthDay)
                                            Text("Cyclical").tag(AdvancedPattern.cyclical)
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    
                                    // Metric Selection
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Metrics to Generate")
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Button("Customize") {
                                                showingMetricCustomization = true
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                        
                                        Text("\(selectedMetrics.count) of \(HealthMetric.allCases.count) metrics selected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        
                        // Generate Button
                        Button(action: {
                            generateHealthDataWithEnhancedConfig()
                        }) {
                            HStack {
                                if healthKitManager.isGeneratingInProgress {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text(healthKitManager.isGeneratingInProgress ? "Generating..." : "Generate Health Data")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(healthKitManager.isGeneratingInProgress ? Color.gray.gradient : Color.green.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(healthKitManager.isGeneratingInProgress)
                        
                        // Import JSON Button
                        Button(action: {
                            showingJSONImport = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Import from JSON")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(healthKitManager.isGeneratingInProgress)
                        
                        // Clean Button
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
                                }
                                Text(healthKitManager.isCleaningInProgress ? "Cleaning..." : "Clean Health Data")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(healthKitManager.isCleaningInProgress ? Color.gray.gradient : Color.red.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(healthKitManager.isCleaningInProgress)
                        
                        // Cleaning Progress
                        if healthKitManager.isCleaningInProgress {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cleaning Progress")
                                    .font(.headline)
                                
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
                
                    // Footer
                    Text("Built with SwiftUI & HealthKit")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
        .alert("Health Data", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingJSONImport) {
            JSONImportView()
        }
        .sheet(isPresented: $showingMetricCustomization) {
            MetricCustomizationView(selectedMetrics: $selectedMetrics)
        }
        .task {
            if HKHealthStore.isHealthDataAvailable() && !healthKitManager.isAuthorized {
                await healthKitManager.requestAuthorization()
            }
        }
    }
    
    // MARK: - Enhanced Generation Method
    
    private func generateHealthDataWithEnhancedConfig() {
        // Create date range based on selection
        let dateRange: DateRange
        switch selectedDateRangeType {
        case .lastDays:
            dateRange = .lastDays(sampleCount)
        case .thisWeek:
            dateRange = .thisWeek()
        case .thisMonth:
            dateRange = .thisMonth()
        case .weekdaysOnly:
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -Int(sampleCount), to: endDate) ?? endDate
            dateRange = .weekdaysOnly(start: startDate, end: endDate)
        case .weekendsOnly:
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -Int(sampleCount), to: endDate) ?? endDate
            dateRange = .weekendsOnly(start: startDate, end: endDate)
        case .specificDates:
            // For now, fall back to last days - could be enhanced with date picker
            dateRange = .lastDays(sampleCount)
        }
        
        // Create enhanced configuration
        let config = SampleGenerationConfig(
            profile: selectedProfile,
            dateRange: dateRange,
            metricsToGenerate: selectedMetrics,
            pattern: selectedPattern,
            randomSeed: nil,
            customOverrides: nil
        )
        
        // Generate with enhanced config
        healthKitManager.generateHealthData(config: config)
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
                        Button("Select All") {
                            selectedMetrics = Set(HealthMetric.allCases)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Select None") {
                            selectedMetrics.removeAll()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Customize Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - JSON Import View

struct JSONImportView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var jsonText = ""
    @State private var isValidating = false
    @State private var validationMessage = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Import Health Data from JSON")
                    .font(.headline)
                    .padding(.top)
                
                Text("Paste JSON generated by Foundation Model or custom configuration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextEditor(text: $jsonText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(validationMessage.contains("✅") ? .green : .red)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 12) {
                    Button("Validate") {
                        validateJSON()
                    }
                    .buttonStyle(.bordered)
                    .disabled(jsonText.isEmpty || isValidating)
                    
                    Button("Import") {
                        importJSON()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(jsonText.isEmpty || healthKitManager.isGeneratingInProgress)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Import JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Paste Example") {
                        jsonText = exampleJSON
                    }
                }
            }
        }
    }
    
    private func validateJSON() {
        isValidating = true
        validationMessage = "Validating..."
        
        Task {
            do {
                let generator = HealthKitDataGenerator(healthStore: healthKitManager.healthStore)
                let isValid = try generator.validateLLMJSON(jsonText)
                
                await MainActor.run {
                    validationMessage = isValid ? "✅ Valid JSON" : "❌ Invalid JSON"
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    validationMessage = "❌ \(error.localizedDescription)"
                    isValidating = false
                }
            }
        }
    }
    
    private func importJSON() {
        healthKitManager.importFromJSON(jsonText)
        dismiss()
    }
    
    private var exampleJSON: String {
        """
        {
          "schema_version": "1.0",
          "generation_config": {
            "profile": {
              "id": "example",
              "name": "Example Profile",
              "description": "Sample profile for testing",
              "dailyStepsRange": {"lowerBound": 8000, "upperBound": 12000},
              "workoutFrequency": "moderate",
              "preferredWorkoutTypes": ["running", "yoga"],
              "sleepDurationRange": {"lowerBound": 7.0, "upperBound": 8.5},
              "sleepQuality": "good",
              "bedtimeRange": {"lowerBound": 21, "upperBound": 26},
              "restingHeartRateRange": {"lowerBound": 60, "upperBound": 70},
              "maxHeartRateRange": {"lowerBound": 170, "upperBound": 185},
              "heartRateVariability": "moderate",
              "basalEnergyMultiplier": 1.0,
              "activeEnergyRange": {"lowerBound": 400, "upperBound": 800},
              "stressLevel": "moderate",
              "recoveryRate": "average",
              "dietaryPattern": "mediterranean",
              "hydrationLevel": "moderate"
            },
            "dateRange": {
              "startDate": "2025-01-01T00:00:00Z",
              "endDate": "2025-01-07T23:59:59Z"
            },
            "metricsToGenerate": ["steps", "heart_rate", "sleep_analysis"],
            "pattern": "continuous"
          }
        }
        """
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
