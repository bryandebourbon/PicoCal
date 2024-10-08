import Combine
import WidgetKit
import SwiftUI

@MainActor
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
        let mergedFlags = orBooleanArrays(newLocal, self.watchStoreLocal)
        Store.shared.persist(data: mergedFlags, forKey: "sharedFlags")
        self.watchStoreLocal = mergedFlags
        WidgetCenter.shared.reloadAllTimelines()
      }
      .store(in: &cancellables)
  }

  func refresh(health: Health) async {
    health.fetchCaloriesByMonth()
    let newHealthData = health.caloriesByMonth
    let mergedFlags = orBooleanArrays(phoneCxnLocal, newHealthData)
    Store.shared.persist(data: mergedFlags, forKey: "sharedFlags")
    watchStoreLocal = mergedFlags
    WidgetCenter.shared.reloadAllTimelines()
  }
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

}
