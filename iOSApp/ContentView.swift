import EventKit
import HealthKit
import SwiftUI
import WidgetKit

struct ContentView: View {
  @StateObject var store = Store()
  var health = Health()
  var watch = Watch()

  let eventKitFetcher = EventKitFetcher()

  func refresh() async {
    health.fetchCaloriesByMonth()
    store.local = health.caloriesByMonth
    watch.send(data: health.caloriesByMonth)
    WidgetCenter.shared.reloadAllTimelines()
  }

  var body: some View {
    VStack {
      CalendarView(
        calorieDays: $store.local
      )
      Button("🔄") {
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
