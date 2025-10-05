import SwiftUI
import HealthKit

public struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var sampleCount: Int = 2
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                        // Sample Count Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Number of days")
                                .font(.headline)
                            
                            HStack {
                                TextField("Sample Count", value: $sampleCount, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Stepper("", value: $sampleCount, in: 1...10000, step: 1)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        
                        // Generate Button
                        Button(action: {
                            healthKitManager.generateHealthData(count: sampleCount)
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
        .task {
            if HKHealthStore.isHealthDataAvailable() && !healthKitManager.isAuthorized {
                await healthKitManager.requestAuthorization()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
