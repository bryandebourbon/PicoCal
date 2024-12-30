import SwiftUI
import Combine

@MainActor
final class CentralViewModel: ObservableObject, CalendarViewProviding {
  @Published var healthFlags: [Bool] = []
  @Published var busyDays: [(Bool, Bool, Bool)] = []

  private let dataManager = DataManager.shared

  // MARK: - Refresh
  func refresh() async {
    #if os(watchOS)
    await refreshForWatch()
    #else
    await refreshForPhone()
    #endif
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
}

// MARK: - WATCH-ONLY
#if os(watchOS)
import WatchConnectivity

extension CentralViewModel {
  func refreshForWatch() async {
    // 1) Refresh all data from Health + EventKit via the shared DataManager
    await dataManager.refreshAllData()

    // 2) Merge the newly fetched HealthKit data with the watch’s phone.local data
    let newHealthData = dataManager.store.local
    let phoneLocal = WatchToPhone.shared.local
    let merged = orBooleanArrays(newHealthData, phoneLocal)

    // 3) Persist if needed
    dataManager.store.persist(data: merged, forKey: "sharedFlags")
    self.healthFlags = merged

    // 4) Build busy days
    buildBusyDays()
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

    }
  }
}

#endif

// MARK: - CalendarViewProviding conformance
extension CentralViewModel {
  // These are required by the protocol
  // (most likely used by your SwiftUI Views)
}

// MARK: - Helper
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
