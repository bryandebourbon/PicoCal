import SwiftUI
import Combine

@MainActor
final class CentralViewModel: ObservableObject, @preconcurrency CalendarViewProviding {
  @Published var healthFlags: [Bool] = []
  @Published var busyDays: [(Bool, Bool, Bool)] = []
  @Published var showSyncCompletedPopup = false
  @Published var holidayDates: Set<Date> = []
  private let dataManager = DataManager.shared
    

  // MARK: - Refresh
  func refresh() async {
    #if os(watchOS)
    await refreshForWatch()
    #else
    await refreshForPhone()
    #endif
      showSyncCompletedPopup = true
  }

  // MARK: - Common code for both platforms
  private func buildBusyDays() {
    // 1) Build a bounded day range for the current month
    let calendar = Calendar.current
    let now = Date()
    let startOfMonth = calendar.startOfMonth(for: now)
    guard let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
      print("[CentralViewModel] Could not find day range for current month.")
      return
    }

    // 2) Calculate busy days using EventKit
    self.busyDays = dataManager.eventKit.calculateBusyPeriods(
      for: startOfMonth,
      range: dayRange
    )
  }
    
    private func buildHolidayDays() async {
      do {
        // Attempt to fetch holiday events
        let fetchedHolidays = try await dataManager.eventKit.fetchHolidayDatesForCurrentMonth()
        self.holidayDates = fetchedHolidays
      } catch {
        print("Failed to fetch holiday dates: \(error)")
      }
    }
}

// MARK: - WATCH-ONLY
#if os(watchOS)
import WatchConnectivity

extension CentralViewModel {

    func refreshForWatch() async {
    // 1) Refresh from HealthKit + EventKit
    await dataManager.refreshAllData()

    // 2a) Retrieve what's currently in sharedFlags (could have older true days)
    let existingFlags = dataManager.store.retrieve(forKey: "sharedFlags")

    // 2b) The newly fetched watch data
    let newHealthData = dataManager.store.local

    // 2c) The phone’s data
    let phoneLocal = WatchToPhone.shared.local

    // 3) Combine all three: existingFlags ∨ newWatchData ∨ phoneLocal
    let mergedStep1 = orBooleanArrays(existingFlags, newHealthData)
    let mergedStep2 = orBooleanArrays(mergedStep1, phoneLocal)

    // 4) Persist the final merged result
    dataManager.store.persist(data: mergedStep2, forKey: "sharedFlags")
    self.healthFlags = mergedStep2

    // 5) Update your busyDays, holidayDates, etc.
    buildBusyDays()
    await buildHolidayDays()
  }

}

#else

// MARK: - PHONE-ONLY
extension CentralViewModel {
  func refreshForPhone() async {
    do {
      // 1) Refresh from DataManager
      await dataManager.refreshAllData()

      // 2) Pull the latest from the store
      self.healthFlags = dataManager.store.local

      // 3) Try sending data to the Watch
      do {
        let reply = try await PhoneToWatch.shared.sendMessageAsync(data: self.healthFlags)
        print("Phone → Watch success: \(reply)")
      } catch {
        print("Phone → Watch error sending data: \(error)")
      }
        // 3) Persist if needed
        dataManager.store.persist(data: self.healthFlags, forKey: "sharedFlags")

      // 4) Build busy days
      buildBusyDays()

        await buildHolidayDays()
    }
  }
}

#endif

/// Merges two arrays of Booleans, preserving `true` values.
/// Once a day is `true`, it stays `true` going forward.
func orBooleanArrays(_ array1: [Bool], _ array2: [Bool]) -> [Bool] {
    let maxLength = max(array1.count, array2.count)
    var result = [Bool](repeating: false, count: maxLength)

    for i in 0..<maxLength {
        let val1 = (i < array1.count) ? array1[i] : false
        let val2 = (i < array2.count) ? array2[i] : false
        // ALWAYS OR them so once `true` is set, it remains true
        result[i] = val1 || val2
    }

    return result
}
