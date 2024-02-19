import Combine
import Foundation
import HealthKit

class HealthKitVM: ObservableObject {
  @Published var calorieFlags: [Bool] = []
  private let healthStore = HKHealthStore()

  init() {
    requestHealthKitAuthorization()
  }

  func requestHealthKitAuthorization() {
    guard HKHealthStore.isHealthDataAvailable() else {
//      print("HealthKit is not available on this device.")
      return
    }

    let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!]

    healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
      [weak self] success, error in
      if success {
        self?.fetchCaloriesBurnedForCurrentMonth()
      } else {
//        print("Authorization failed: \(String(describing: error))")
      }
    }
  }

  func fetchCaloriesBurnedForCurrentMonth() {
    guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
      return
    }

    let calendar = Calendar.current
    let now = Date()
    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

    let predicate = HKQuery.predicateForSamples(
      withStart: startOfMonth, end: endOfMonth, options: .strictStartDate)
    let query = HKStatisticsCollectionQuery(
      quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum,
      anchorDate: startOfMonth, intervalComponents: DateComponents(day: 1))

    query.initialResultsHandler = { [weak self] query, results, error in
      guard let results = results else {
//        print("Failed to fetch calorie data: \(String(describing: error))")
        return
      }

      let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)!.count
      var dailyFlags = [Bool](repeating: false, count: daysInMonth)

      results.enumerateStatistics(from: startOfMonth, to: endOfMonth) { statistic, stop in
        if let sum = statistic.sumQuantity() {
          let calories = sum.doubleValue(for: HKUnit.kilocalorie())
          let dayIndex = calendar.component(.day, from: statistic.startDate)
          if dayIndex > 0 && dayIndex <= dailyFlags.count {
            dailyFlags[dayIndex - 1] = false//calories > 500
          }
        }
      }

      DispatchQueue.main.async {
        // Prepending [false] may no longer be necessary if the array is correctly initialized
        self?.calorieFlags = dailyFlags
      }
    }

    healthStore.execute(query)

  }
}
