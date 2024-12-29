import SwiftUI

@MainActor
final class CentralViewModel: ObservableObject, CalendarViewProviding {
  @Published var healthFlags: [Bool] = []
  @Published var busyDays: [(Bool, Bool, Bool)] = []

  private let dataManager = DataManager.shared

  func refresh() async {
    do {
      // 1) Refresh from data manager
      await dataManager.refreshAllData()

      // 2) Read latest from data manager’s store/fields
      self.healthFlags = dataManager.store.local

      // 3) Build a bounded day range for the current month
      let calendar = Calendar.current
      let now = Date()
      let startOfMonth = calendar.startOfMonth(for: now)

      guard let dayRange = calendar.range(of: .day,
                                          in: .month,
                                          for: startOfMonth)
      else {
        print("[CentralViewModel] Could not find day range for current month.")
        return
      }

      // 4) Calculate busy days using the bounded range
      self.busyDays = dataManager.eventKit.calculateBusyPeriods(
        for: startOfMonth,
        range: dayRange
      )

    }
  }
}
