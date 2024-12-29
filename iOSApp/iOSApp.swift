import SwiftUI
import WidgetKit

@main
struct iOSApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      iOSContentView()
    }
  }
}

struct iOSContentView: View {
  // 1) Use the new central view model
  @StateObject private var viewModel = CentralViewModel()

  var body: some View {
    VStack {
      CalendarDateTitle()
      CalendarView(viewModel: viewModel) // <— Pass the VM directly
        .frame(width: 170, height: 100)
        .padding()

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
  iOSContentView()
}
