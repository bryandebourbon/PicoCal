import HealthKit

class HealthDataFetcher {
  let healthStore = HKHealthStore()

  func fetchCaloriesBurned(completion: @escaping (Result<[String: Double], Error>) -> Void) {
    guard HKHealthStore.isHealthDataAvailable(), let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
      completion(.failure(NSError(domain: "HealthKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"])))
      return
    }

    let calendar = Calendar.current
    let now = Date()
    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    let predicate = HKQuery.predicateForSamples(withStart: startOfMonth, end: now, options: .strictStartDate)

    let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
      guard let result = result, error == nil else {
        completion(.failure(error ?? NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Query failed"])))
        return
      }

      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      var dailyCalories: [String: Double] = [:]

      if let sum = result.sumQuantity() {
        let calories = sum.doubleValue(for: .kilocalorie())
        let dateKey = dateFormatter.string(from: now) // For simplicity, using 'now', but you should adjust as needed
        dailyCalories[dateKey] = calories
      }

      completion(.success(dailyCalories))
    }

    healthStore.execute(query)
  }
}
