import Combine
import WidgetKit
import SwiftUI

class ContentViewModel: ObservableObject {
  @Published var watchStoreLocal: [Bool] = []
  @Published var phoneCxnLocal: [Bool] = []

  private var cancellables = Set<AnyCancellable>()

  init(phoneCxn: WatchToPhone) {
    // Subscribe to changes in phoneCxn.local
    phoneCxn.$local
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newLocal in
        guard let self = self else { return }
        self.phoneCxnLocal = newLocal
        let mergedFlags = zip(newLocal, self.watchStoreLocal).map { $0 || $1 }
        Store.shared.persist(data: mergedFlags, forKey: "sharedFlags")
        self.watchStoreLocal = mergedFlags
        WidgetCenter.shared.reloadAllTimelines()
      }
      .store(in: &cancellables)
  }

  func refresh(health: Health) async {
    health.fetchCaloriesByMonth()
    let newHealthData = health.caloriesByMonth
    let mergedFlags = zip(phoneCxnLocal, newHealthData).map { $0 || $1 }
    Store.shared.persist(data: mergedFlags, forKey: "sharedFlags")
    watchStoreLocal = mergedFlags
    WidgetCenter.shared.reloadAllTimelines()
  }
}
