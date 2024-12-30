import SwiftUI

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
      CalendarView(viewModel: viewModel)
      Button("Sync") {
        Task { await viewModel.refresh() }
      }
    }
  }
}

#Preview {
    WatchContentView()
}
