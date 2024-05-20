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
  @StateObject var watchStore = Store()
  @StateObject private var phoneCxn = WatchToPhone()
  var health = Health()

  func refresh() async {
    health.fetchCaloriesByMonth()
    watchStore.local = health.caloriesByMonth
    Store.shared.persist(data: watchStore.local, forKey: "sharedFlags")
    WidgetCenter.shared.reloadAllTimelines()
  }

  var body: some View {
    VStack {
      Spacer()
      Spacer()
      CalendarView(calorieDays: $watchStore.local)
        .frame(width:170, height: 100)
      Spacer()
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


