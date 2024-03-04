import EventKit
import HealthKit
import SwiftUI
import WidgetKit

struct ContentView: View {
  @StateObject var healthKitVM = HealthKitVM()

  let store = SharedUserDefaults()
  let eventKitFetcher = EventKitFetcher()

  var body: some View {
    VStack {
      CalendarView(
        calorieDays: $healthKitVM.calorieFlags
      )
      Button("🔄") {
        healthKitVM.fetchCaloriesBurnedForCurrentMonth()
        store.saveEvents(healthKitVM.calorieFlags, calorieDays: healthKitVM.calorieFlags)
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
    .onAppear {
      //eventKitFetcher.initializeEventStore { granted, events, error in
      //        if let events = events as? [EventWrapper] {
      //          self.eventDays = events
      //        } else if let error = error {
      //          print("An error occurred: \(error.localizedDescription)")
      //        }
      //
      //      }
      healthKitVM.fetchCaloriesBurnedForCurrentMonth()

      store.saveEvents(healthKitVM.calorieFlags, calorieDays: healthKitVM.calorieFlags)
    }
  }
}

#Preview{
  ContentView()
}
