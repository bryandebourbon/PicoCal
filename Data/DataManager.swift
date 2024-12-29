
final class DataManager {
  static let shared = DataManager()

  let store = Store.shared
  let health = Health()
  let eventKit = EventKitFetcher.shared

  private init() { }

  /// Perform a unified refresh for Health + EventKit + local store.
  func refreshAllData() async {
    do {
      // HealthKit
      let newHealthData = try await health.fetchCaloriesByMonth()
      store.local = newHealthData  // or store.persist(...)

      // EventKit
      let busyDays = try await eventKit.initializeEventStore()
      // Possibly store or transform busyDays here

    } catch {
      // Handle or log any error
      print("[DataManager] refreshAllData error: \(error)")
    }
  }
}
