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
      print("HealthKit is not available on this device.")
      return
    }

    let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!]

    healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
      if success {
        self?.fetchCaloriesBurnedForCurrentMonth()
      } else {
        print("Authorization failed: \(String(describing: error))")
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
    let endOfToday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)

    let predicate = HKQuery.predicateForSamples(withStart: startOfMonth, end: endOfToday, options: .strictStartDate)
    let query = HKStatisticsCollectionQuery(
      quantityType: calorieType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: startOfMonth,
      intervalComponents: DateComponents(day: 1))

    query.initialResultsHandler = { [weak self] query, results, error in
      guard let results = results else {
        print("Failed to fetch calorie data: \(String(describing: error))")
        return
      }

      let totalDays = calendar.dateComponents([.day], from: startOfMonth, to: endOfToday).day!
      var dailyFlags = [Bool](repeating: false, count: totalDays)

      results.enumerateStatistics(from: startOfMonth, to: endOfToday) { statistic, stop in
        if let sum = statistic.sumQuantity() {
          let calories = sum.doubleValue(for: HKUnit.kilocalorie())
          if let daysAgo = calendar.dateComponents([.day], from: startOfMonth, to: statistic.startDate).day {
            dailyFlags[daysAgo] = calories > 500
          }
        }
      }

      DispatchQueue.main.async {
        self?.calorieFlags = dailyFlags
      }
    }

    healthStore.execute(query)
  }
}
