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
    let startOfMonth = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)
    let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!

    print("Fetching data from \(startOfMonth) to \(endOfToday)")

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
        let date = statistic.startDate
        print("Processing date: \(date)")

        if let sum = statistic.sumQuantity() {
          let calories = sum.doubleValue(for: HKUnit.kilocalorie())
          print("Calories for \(date): \(calories)")
          dailyFlags.append(calories > 500)
        } else {
          print("No data for \(date)")
          dailyFlags.append(false)
        }
      }

      self.caloriesByMonth = dailyFlags
      print(dailyFlags)
    }

    healthStore.execute(query)
  }
}
