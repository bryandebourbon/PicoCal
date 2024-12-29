@MainActor
final class CentralViewModel: ObservableObject {
  @Published var healthFlags: [Bool] = []
  @Published var busyDays: [(Bool, Bool, Bool)] = []

  private let dataManager = DataManager.shared

  func refresh() async {
    do {
      // 1) Refresh from data manager
      await dataManager.refreshAllData()

      // 2) Read latest from data manager’s store/fields
      self.healthFlags = dataManager.store.local

      // If you want to store busy days in the data manager or eventKit:
      self.busyDays = dataManager.eventKit.calculateBusyPeriods(
        for: ...,
        range: ...
      )
      // or if you changed DataManager to store them in memory, read from there
    }
  }
}
