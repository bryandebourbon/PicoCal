import Combine
import Foundation
import HealthKit

class Health {
  let healthStore = HKHealthStore()
  var caloriesByMonth: [Bool] = []

  init() {
    requestHealthKitAuthorization()
  }

  func requestHealthKitAuthorization() {
    guard HKHealthStore.isHealthDataAvailable() else {
      print("HealthKit is not available on this device.")
      return
    }

    let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!]

    healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
      [weak self] success, error in
      if success {
        self?.fetchCaloriesByMonth()
      } else {
        print("Authorization failed: \(String(describing: error))")
      }
    }
  }

  func fetchCaloriesByMonth() {
    guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
      return
    }

    let calendar = Calendar.current
    let now = Date()
    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    let endOfToday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)

    print(startOfMonth)
    print(endOfToday)

    let predicate = HKQuery.predicateForSamples(
      withStart: startOfMonth, end: endOfToday, options: .strictStartDate)
    let query = HKStatisticsCollectionQuery(
      quantityType: calorieType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: startOfMonth,
      intervalComponents: DateComponents(day: 1))

    query.initialResultsHandler = { [weak self] query, results, error in
      guard let self = self, let results = results else {
        print("Failed to fetch calorie data: \(String(describing: error))")
        return
      }

      var dailyFlags: [Bool] = []

      results.enumerateStatistics(from: startOfMonth, to: endOfToday) { statistic, stop in
        if let sum = statistic.sumQuantity() {
          let calories = sum.doubleValue(for: HKUnit.kilocalorie())
          dailyFlags.append(calories > 500)
          print(dailyFlags)
        }
      }

      self.caloriesByMonth = dailyFlags

      print(dailyFlags)

    }

    healthStore.execute(query)
  }
}
