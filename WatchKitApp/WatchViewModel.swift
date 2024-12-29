import SwiftUI
import Combine

@MainActor
final class WatchCentralViewModel: ObservableObject, CalendarViewProviding {

  @Published var healthFlags: [Bool] = []
  @Published var busyDays: [(Bool, Bool, Bool)] = []

  private let dataManager = DataManager.shared
  private let phone = WatchToPhone()

  func refresh() async {
    // 1) Refresh all data from Health + EventKit via the shared DataManager
    await dataManager.refreshAllData()

    // 2) Merge HealthKit data (in store) with watch’s phone.local data
    let newHealthData = dataManager.store.local
    let phoneLocal = phone.local
    let merged = orBooleanArrays(newHealthData, phoneLocal)

    // 3) Persist if needed
    dataManager.store.persist(data: merged, forKey: "sharedFlags")
    self.healthFlags = merged

    // 4) Calculate busy days using EventKit’s day range
    let calendar = Calendar.current
    let now = Date()
    let startOfMonth = calendar.startOfMonth(for: now)
    guard let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
      print("[WatchCentralViewModel] Could not find day range for current month.")
      return
    }
    self.busyDays = dataManager.eventKit.calculateBusyPeriods(
      for: startOfMonth,
      range: dayRange
    )
  }
}

/// Helper function to OR two boolean arrays
func orBooleanArrays(_ array1: [Bool], _ array2: [Bool]) -> [Bool] {
  let maxLength = max(array1.count, array2.count)
  var resultArray: [Bool] = []

  for i in 0..<maxLength {
    let value1 = i < array1.count ? array1[i] : false
    let value2 = i < array2.count ? array2[i] : false
    resultArray.append(value1 || value2)
  }
  return resultArray
}
