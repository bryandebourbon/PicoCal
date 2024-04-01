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
  //  @StateObject var store = Store()
  var health = Health()
  @StateObject private var connectivityProvider = WatchConnectivityProvider()

  func refresh() async {
    Store.shared.persist(data: connectivityProvider.local, forKey: "sharedFlags")
    WidgetCenter.shared.reloadAllTimelines()
  }


  var body: some View {
    VStack {
      CalendarView(calorieDays: $connectivityProvider.local)
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


