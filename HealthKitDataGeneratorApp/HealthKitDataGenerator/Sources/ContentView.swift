import SwiftUI
import HealthKit
import HealthKitDataGenerator

public struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var sampleCount: Int = 7
    @State private var selectedProfile: HealthProfile = .balanced
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingJSONImport = false
    
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
                            
                            Picker("Profile", selection: $selectedProfile) {
                                ForEach(HealthProfile.allPresets, id: \.id) { profile in
                                    Text(profile.name).tag(profile)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text(selectedProfile.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        
                        // Sample Count Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Number of Days")
                                .font(.headline)
                            
                            HStack {
                                TextField("Days", value: $sampleCount, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Stepper("", value: $sampleCount, in: 1...90, step: 1)
                            }
                            
                            Text("Generate data for the last \(sampleCount) day\(sampleCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        
                        // Generate Button
                        Button(action: {
                            healthKitManager.generateHealthData(count: sampleCount, profile: selectedProfile)
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
        .task {
            if HKHealthStore.isHealthDataAvailable() && !healthKitManager.isAuthorized {
                await healthKitManager.requestAuthorization()
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
              "bedtimeRange": {"lowerBound": 22, "upperBound": 23},
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
