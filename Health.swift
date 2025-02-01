import Foundation
import HealthKit

/// Possible HealthKit errors.
enum HealthKitError: Error {
    case notAvailable
    case invalidQuantityType
    case authorizationFailed
}

/// A singleton class for accessing HealthKit data with async/await.
final class Health {
    
    /// The single shared instance.
    static let shared = Health()
    
    /// The underlying HKHealthStore we'll use.
    let healthStore = HKHealthStore()
    
    /// The latest "calories by month" flags, updated after calling `fetchCaloriesByMonth()`.
    private(set) var caloriesByMonth: [Bool] = []
    
    /// Make the initializer private so only `Health.shared` can be used.
    private init() { }
    
    /// Request authorization to read from HealthKit.
    /// If not available or the user denies permission, this call will throw an error.
    @MainActor
    func requestHealthKitAuthorization() async throws {
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
    /// Returns an array of Booleans. Each `Bool` indicates whether that day's calories > 500.
    func fetchCaloriesByMonth() async throws -> [Bool] {
        // Add this at the start of the method
        if shouldClearHealthData() {
            self.caloriesByMonth = []
            // Clear the stored data
            DataManager.shared.store.persist(data: [], forKey: "sharedFlags")
        }
        
        // 1) Make sure HealthKit is available on this device.
//        guard HKHealthStore.isHealthDataAvailable() else {
//            print("[Health] HealthKit is not available on this device.")
//            throw HealthKitError.notAvailable
//        }
        
        // 2) Make sure we can read the .activeEnergyBurned type.
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            print("[Health] Invalid quantity type for activeEnergyBurned.")
            throw HealthKitError.invalidQuantityType
        }

        // 3) Check current authorization status for this type.
//        let status = healthStore.authorizationStatus(for: calorieType)
//        switch status {
//        case .notDetermined:
//            // User has not yet responded – request permission now.
            try await requestHealthKitAuthorization()
//        case .sharingDenied:
//            // User has already denied – throw an error (or handle gracefully).
//            print("[Health] User previously denied HealthKit permission.")
//            throw HealthKitError.authorizationFailed
//        case .sharingAuthorized:
//            // User has already granted permission; just continue.
//            break
//        @unknown default:
//            // Future-proof: handle any new/unknown cases.
//            throw HealthKitError.authorizationFailed
//        }

        // 4) Now that we are sure we have authorization (or we threw above), fetch data.
        let calendar = Calendar.current
        let now = Date()
        
        // Start of current month.
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            print("[Health] Could not find start of month for current date.")
            return []
        }
        
        // End of today = 23:59:59
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
            
            // Execute the query
            self.healthStore.execute(query)
            print("[Health] Executing HKStatisticsCollectionQuery...")
        }
        
        self.caloriesByMonth = dailyFlags
        print("[Health] Finished fetching daily flags: \(dailyFlags)")
        
        return dailyFlags
    }

    func shouldClearHealthData() -> Bool {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let now = Date()
        
        // Get stored month/year
        let lastMonth = defaults.integer(forKey: "lastHealthMonth")
        let lastYear = defaults.integer(forKey: "lastHealthYear")
        
        // Get current month/year
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // If we have no stored date or the month/year has changed
        if lastMonth == 0 || lastYear == 0 ||
           lastMonth != currentMonth ||
           lastYear != currentYear {
            
            // Update stored month/year
            defaults.set(currentMonth, forKey: "lastHealthMonth")
            defaults.set(currentYear, forKey: "lastHealthYear")
            
            print("[Health] Month changed from \(lastMonth)/\(lastYear) to \(currentMonth)/\(currentYear). Clearing health data.")
            return true
        }
        
        return false
    }
}
