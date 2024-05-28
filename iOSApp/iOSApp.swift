import SwiftUI
import EventKit
import HealthKit
import WidgetKit

@main
struct iOSApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @StateObject var phoneStore = Store()
  var health = Health()
  var watch = PhoneToWatch()

  @State private var eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]?

  let eventKitFetcher = EventKitFetcher.shared

  func refresh() async {
    health.fetchCaloriesByMonth()
    phoneStore.local = health.caloriesByMonth
    watch.send(data: health.caloriesByMonth)
    WidgetCenter.shared.reloadAllTimelines()

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

      CalendarDateTitle()
      CalendarView(
        calorieDays: $phoneStore.local, eventDays: $eventDays
      )
      .frame(width: 170, height: 100)
      .padding()
      Button("Sync") {
        Task {
          await refresh()
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
