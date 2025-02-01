import SwiftUI
import WidgetKit

@main
struct WatchKitApp: App {
  var body: some Scene {
    WindowGroup {
      WatchContentView()
    }
  }
}

struct WatchContentView: View {
  @StateObject var viewModel = CentralViewModel()
  @Environment(\.scenePhase) private var scenePhase
  
  var body: some View {
    NavigationView {
      CalendarView(viewModel: viewModel)
        .ignoresSafeArea()
        .onAppear {
          refreshData()
        }
        // Add scene phase handling for background/foreground transitions
        .onChange(of: scenePhase) { newPhase in
          if newPhase == .active {
            refreshData()
          }
        }
    }
  }
  
  private func refreshData() {
    Task {
      await viewModel.refresh()
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}

#Preview {
    WatchContentView()
}
