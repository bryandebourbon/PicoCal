import SwiftUI
import WidgetKit

@main
struct WatchKitApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
      Spacer()
      Button("Update Widget") {

        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }
}

#Preview{
  ContentView()
}
