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
  @StateObject private var phoneCxn = WatchToPhone()
  @StateObject private var viewModel: ContentViewModel

  @State private var eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]?

  var health = Health()
  let eventKitFetcher = EventKitFetcher.shared

  init() {
    let phoneCxn = WatchToPhone()
    _phoneCxn = StateObject(wrappedValue: phoneCxn)
    _viewModel = StateObject(wrappedValue: ContentViewModel(phoneCxn: phoneCxn))
  }

  func refresh() async {
    health.fetchCaloriesByMonth()
    viewModel.watchStoreLocal = health.caloriesByMonth

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
      CalendarView(calorieDays: $viewModel.watchStoreLocal, eventDays: $eventDays)
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

#Preview {
  ContentView()
}
