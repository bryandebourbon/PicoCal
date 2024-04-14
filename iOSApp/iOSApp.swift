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

  let eventKitFetcher = EventKitFetcher()

  func refresh() async {
    health.fetchCaloriesByMonth()
    phoneStore.local = health.caloriesByMonth
    watch.send(data: health.caloriesByMonth)
    WidgetCenter.shared.reloadAllTimelines()
  }

  var body: some View {
    VStack {
      CalendarView(
        calorieDays: $phoneStore.local
      )
      Button("Sync") {
        Task {
          await refresh()
        }
      }
    }
  }
}

#Preview{
  ContentView()
}
#Preview {
  ContentView()
}
