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
        let mergedFlags = self.orBooleanArrays(newLocal, self.watchStoreLocal)
        Store.shared.persist(data: mergedFlags, forKey: "sharedFlags")
        self.watchStoreLocal = mergedFlags
        WidgetCenter.shared.reloadAllTimelines()
      }
      .store(in: &cancellables)
  }

  /// Refresh logic that awaits HealthKit data:
  func refresh(health: Health) async {
    do {
      // 1) Await the async/throwing call
      let newHealthData = try await health.fetchCaloriesByMonth()
      
      // 2) Merge new data with phoneCxnLocal
      let mergedFlags = orBooleanArrays(phoneCxnLocal, newHealthData)
      Store.shared.persist(data: mergedFlags, forKey: "sharedFlags")
      watchStoreLocal = mergedFlags
      WidgetCenter.shared.reloadAllTimelines()

    } catch {
      // 3) Handle any errors from HealthKit
      print("[Health] Error in fetchCaloriesByMonth: \(error)")
    }
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
