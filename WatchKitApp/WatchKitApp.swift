import EventKit
import HealthKit
import SwiftUI
import WidgetKit

@main
struct WatchKitApp: App {
  var body: some Scene {
    WindowGroup {
      VStack {
          WatchContentView()
      }
//      .edgesIgnoringSafeArea(.all)
    }
  }
}

struct WatchContentView: View {
  @StateObject var viewModel = WatchCentralViewModel()

  var body: some View {
    VStack {
      CalendarView(viewModel: viewModel)  // <— T is WatchCentralViewModel
      Button("Sync") {
        Task { await viewModel.refresh() }
      }
    }
  }
}


#Preview {
    WatchContentView()
}
