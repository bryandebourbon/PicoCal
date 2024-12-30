import SwiftUI
import WidgetKit

@main
struct WatchKitApp: App {
  var body: some Scene {
    WindowGroup {
      VStack {
          WatchContentView()
      }
    }
  }
}

struct WatchContentView: View {
  @StateObject var viewModel = CentralViewModel()
  var body: some View {
    VStack {
//      CalendarDateTitle()
      CalendarView(viewModel: viewModel)
      Button("Sync") {
          Task {
              await viewModel.refresh()
              WidgetCenter.shared.reloadAllTimelines()
          }
      }
    }
  }
}

#Preview {
    WatchContentView()
}
