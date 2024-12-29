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
    // 1) Fetch HealthKit data using `try await`
    do {
      let newHealthData = try await health.fetchCaloriesByMonth()
      phoneStore.local = newHealthData
      watch.send(data: newHealthData)
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      // Handle/Log HealthKit error (e.g. authorization denied, etc.)
      print("[Health] Error fetching HealthKit data: \(error)")
    }

    // 2) Fetch EventKit data via our new async method
    do {
      let busyDays = try await eventKitFetcher.initializeEventStore()
      eventDays = busyDays
    } catch {
      // Handle/Log EventKit error (permission denied, etc.)
      print("[EventKit] Error initializing EventKit: \(error)")
      // Optional fallback
      eventDays = (1...30).map { _ in (morning: false, afternoon: false, evening: false) }
    }
  }

  var body: some View {
    VStack {
      CalendarDateTitle()
      CalendarView(
        calorieDays: $phoneStore.local,
        eventDays: $eventDays
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
