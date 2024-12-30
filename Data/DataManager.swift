import Foundation

final class DataManager {
    
    /// The single shared DataManager.
    static let shared = DataManager()
    
    // Example references:
    let store = Store.shared              // your local store or persistence
    let eventKit = EventKitFetcher.shared // your event kit fetcher
    let health = Health.shared            // the *singleton* Health
    
    private init() { }
    
    /// Perform a unified refresh for Health + EventKit + local store.
    func refreshAllData() async {
        do {
            // 1) HealthKit
            let newHealthData = try await health.fetchCaloriesByMonth()
            store.local = newHealthData  // or store.persist(...)

            // 2) EventKit
            let busyDays = try await eventKit.initializeEventStore()
            // Possibly store or transform busyDays here

        } catch {
            // Handle or log any error
            print("[DataManager] refreshAllData error: \(error)")
        }
    }
}
