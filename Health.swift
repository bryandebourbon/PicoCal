import Foundation
import HealthKit

/// Possible HealthKit errors.
enum HealthKitError: Error {
  case notAvailable
  case invalidQuantityType
  case authorizationFailed
}

/// A class for accessing HealthKit data with async/await.
class Health {
  let healthStore = HKHealthStore()
  
  /// The latest “calories by month” flags, updated after calling `fetchCaloriesByMonth()`
  private(set) var caloriesByMonth: [Bool] = []

  init() {
    // Remove the call to request authorization here.
    // If you prefer a user-driven approach, you can still keep the call
    // in a button action or some other place. But we won't request
    // in `init` to ensure we only do so when data is actually requested.
  }
  
  /// Request authorization to read from HealthKit.
  /// If not available or the user denies permission, this call will throw an error.
  @MainActor
  private func requestHealthKitAuthorization() async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
      print("[Health] HealthKit is not available on this device.")
      throw HealthKitError.notAvailable
    }

    guard let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
      print("[Health] Invalid quantity type for activeEnergyBurned.")
      throw HealthKitError.invalidQuantityType
    }

    let typesToRead: Set<HKSampleType> = [activeEnergy]

    print("[Health] Requesting HealthKit authorization for: \(typesToRead)")

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
        if let error = error {
          print("[Health] Authorization request encountered an error: \(error.localizedDescription)")
          continuation.resume(throwing: error)
        } else if !success {
          print("[Health] Authorization request was not granted by the user.")
          continuation.resume(throwing: HealthKitError.authorizationFailed)
        } else {
          print("[Health] HealthKit authorization granted.")
          continuation.resume(returning: ())
        }
      }
    }
  }

  /// Fetch active energy (calories) for the current month.
  /// Returns an array of Bools. Each Bool indicates whether that day’s calories > 500.
  func fetchCaloriesByMonth() async throws -> [Bool] {
    // First, make sure HealthKit is available on this device.
    guard HKHealthStore.isHealthDataAvailable() else {
      print("[Health] HealthKit is not available on this device.")
      throw HealthKitError.notAvailable
    }
    
    // Make sure we can read the .activeEnergyBurned type.
    guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
      print("[Health] Invalid quantity type for activeEnergyBurned.")
      throw HealthKitError.invalidQuantityType
    }

    // Check current authorization status for this type.
    let status = healthStore.authorizationStatus(for: calorieType)

    switch status {
      case .notDetermined:
        // User has not yet responded – request permission now.
        try await requestHealthKitAuthorization()
      case .sharingDenied:
        // User has already denied – throw an error (or handle gracefully).
        print("[Health] User previously denied HealthKit permission.")
        throw HealthKitError.authorizationFailed
      case .sharingAuthorized:
        // User has already granted permission; just continue.
        break
      @unknown default:
        // Future-proof: handle any new/unknown cases.
        throw HealthKitError.authorizationFailed
    }

    // Now that we are sure we have authorization (or we threw above), fetch data.
    
    let calendar = Calendar.current
    let now = Date()

    // Calculate boundaries: start of this month and "end of today".
    guard
      let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
    else {
      print("[Health] Could not find start of month for current date.")
      return []
    }

    guard let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
      print("[Health] Could not compute end of today (23:59:59).")
      return []
    }

    print("[Health] Fetching data from \(startOfMonth) to \(endOfToday).")

    let predicate = HKQuery.predicateForSamples(
      withStart: startOfMonth,
      end: endOfToday,
      options: .strictStartDate
    )

    let query = HKStatisticsCollectionQuery(
      quantityType: calorieType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: startOfMonth,
      intervalComponents: DateComponents(day: 1)
    )
    
    let dailyFlags: [Bool] = try await withCheckedThrowingContinuation { continuation in
      query.initialResultsHandler = { _, results, error in
        if let error = error {
          print("[Health] Error while fetching statistics: \(error.localizedDescription)")
          continuation.resume(throwing: error)
          return
        }
        
        guard let results = results else {
          print("[Health] No results found for specified period. Returning empty array.")
          continuation.resume(returning: [])
          return
        }
        
        var tempFlags: [Bool] = []
        results.enumerateStatistics(from: startOfMonth, to: endOfToday) { statistic, _ in
          if let sum = statistic.sumQuantity() {
            let calories = sum.doubleValue(for: .kilocalorie())
            print("[Health] Date \(statistic.startDate): \(calories) kcal (threshold > 500).")
            tempFlags.append(calories > 500)
          } else {
            print("[Health] Date \(statistic.startDate): No data available.")
            tempFlags.append(false)
          }
        }
        
        continuation.resume(returning: tempFlags)
      }
      
      // Execute the query after setting the handler
      self.healthStore.execute(query)
      print("[Health] Executing HKStatisticsCollectionQuery...")
    }
    
    self.caloriesByMonth = dailyFlags
    print("[Health] Finished fetching daily flags: \(dailyFlags)")
    
    return dailyFlags
  }
}
