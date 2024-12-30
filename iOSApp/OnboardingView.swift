import SwiftUI
import HealthKit


struct OnboardingView: View {
    /// Binding to track whether onboarding is completed.
    @Binding var hasCompletedOnboarding: Bool
    
    /// ObservedObject for the same `CentralViewModel`.
    @ObservedObject var vm: CentralViewModel
    
    /// Health singleton
    private let health = Health.shared
    
    @State private var isRequesting = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to PicoCal")
                .font(.largeTitle)
                .padding(.top)
            
            // TODO: BETTER EXPLAIN that calories cause the calendar day to change color! and also alter wording for app in appstore connect
            Text("We need access to your Health data to track your daily calories. Once you burn more than 500 calories, the current day on your calendar will change color to show you’ve hit your goal.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
            
            if isRequesting {
                ProgressView("Requesting HealthKit permission…")
            }
            
            Button(action: handleAuthorization) {
                Text("Next")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isRequesting)
            
            if errorMessage == "User Denied" {
                Button("Open Settings") {
                    openAppSettings()
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .task {
            // Check the existing HealthKit authorization status on appear
//            await checkInitialAuthorizationStatus()
        }
    }
}

// MARK: - Private Methods

extension OnboardingView {
    
    /// Checks if we’re already authorized, denied, or notDetermined.
    private func checkInitialAuthorizationStatus() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "Health data is not available on this device."
            return
        }
        
//        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
//            errorMessage = "Invalid quantity type for activeEnergyBurned."
//            return
//        }
//        do {try await Health.shared.requestHealthKitAuthorization()
//        }catch {
//            print("Error requesting authorization:")
//        }
//        let status = health.healthStore.authorizationStatus(for: calorieType)
//        switch status {
//        case .sharingAuthorized:
//            // Already authorized, so skip the request entirely.
//            hasCompletedOnboarding = true
//            
//        case .sharingDenied:
//            // The user denied in the past. Show a message and allow them to open Settings.
//            errorMessage = "User Denied"
//            
//        case .notDetermined:
//            // Not determined yet. Wait for the user to tap "Next."
//            break
//            
//        @unknown default:
//            errorMessage = "Unknown authorization status."
//        }
    }
    
    /// Handles the actual permission request when user taps "Next."
    private func handleAuthorization() {
        // If user is already known to have denied, present "Open Settings" instead.
        guard errorMessage != "User Denied" else { return }
        
        Task {
            do {
                isRequesting = true
                // triggers HealthKit request if status == .notDetermined
                _ = try await health.fetchCaloriesByMonth()
    
                await vm.refresh()

                isRequesting = false
                hasCompletedOnboarding = true
            } catch {
                isRequesting = false
                // If the user denies, we throw an error → show "User Denied"
                errorMessage = "User Denied"
            }
        }
    }
    
    /// Let the user open iOS Settings if they previously denied HealthKit.
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
