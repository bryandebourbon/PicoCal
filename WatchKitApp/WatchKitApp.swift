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
      }.edgesIgnoringSafeArea(.all)
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
    health.fetchCaloriesByMonth()
    combinedArray = orBooleanArrays(health.caloriesByMonth, phone.local)
    Store.shared.persist(data: combinedArray, forKey: "sharedFlags")

    eventKitFetcher.initializeEventStore { granted, busyDays, error in
      if granted, let busyDays = busyDays {
        eventDays = busyDays
      } else {
        // Handle error or lack of permissions
      }
    }
  }

  var body: some View {
    VStack {
      Spacer()
      Spacer()
      CalendarView(calorieDays: $combinedArray, eventDays: $eventDays)
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
