import EventKit
import HealthKit
import SwiftUI
import WidgetKit

@main
struct WatchKitApp: App {
  var body: some Scene {
    WindowGroup {
      VStack {
        ContentView()
      }
      .edgesIgnoringSafeArea(.all)
    }
  }
}

struct ContentView: View {
  @StateObject private var phone = WatchToPhone()
  @State private var eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]?
  var health = Health()
  let eventKitFetcher = EventKitFetcher.shared
  @State var combinedArray: [Bool] = []

  func refresh() async {
    // 1) Fetch HealthKit data with try/await
    do {
      let newHealthData = try await health.fetchCaloriesByMonth()
      // 2) Merge it with data from `phone.local`
      combinedArray = orBooleanArrays(newHealthData, phone.local)
      // 3) Persist the merged array
      Store.shared.persist(data: combinedArray, forKey: "sharedFlags")
    } catch {
      // Handle or log HealthKit errors
      print("[Health] Error fetching calories: \(error)")
    }

    // 4) Fetch EventKit data asynchronously
    do {
      let busyDays = try await eventKitFetcher.initializeEventStore()
      eventDays = busyDays
    } catch {
      // Handle error or lack of permissions
      print("[EventKit] Error initializing: \(error)")
      eventDays = (1...30).map { _ in (morning: false, afternoon: false, evening: false) }
    }
  }

  var body: some View {
    VStack {
      Spacer()
      Spacer()
      CalendarDateTitle()
      CalendarView(
        calorieDays: $combinedArray,
        eventDays: $eventDays
      )
      .frame(width: 170, height: 100)
      Spacer()
      Button("Sync") {
        Task {
          await refresh()
        }
      }
    }
  }
}

/// Merges two boolean arrays (OR operation).
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

#Preview {
  ContentView()
}
