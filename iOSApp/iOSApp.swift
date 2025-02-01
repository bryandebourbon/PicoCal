import SwiftUI
import WidgetKit
import HealthKit

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    // 1) Store whether onboarding is complete
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @StateObject private var viewModel = CentralViewModel()
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                // 2) Show your main view if onboarding is finished
                iOSContentView(vm: viewModel)
                    .onAppear {
                        refreshData()
                    }
                    // Add scene phase handling
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .active {
                            refreshData()
                        }
                    }
            } else {
                // 3) Otherwise, show the onboarding flow
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding, vm: viewModel)
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

// MARK: - Main Content View

struct iOSContentView: View {
    // If the parent (iOSApp) owns the @StateObject,
    // then here we can just use @ObservedObject.
    @ObservedObject var vm: CentralViewModel

    var body: some View {
        ZStack{
            VStack{
                NavigationView  {
                    CalendarView(viewModel: vm)
                }
                Button("Sync") {
                    Task {
                        await vm.refresh()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }}
                if vm.showSyncCompletedPopup {
                    SyncCompletedToast {
                        // onHide callback:
                        vm.showSyncCompletedPopup = false
                    }
                    .transition(.identity)  // We'll rely on the offset animation
                    // If you do want a fade or another transition, feel free to replace .identity
                }
            
        }
    }
}

#Preview {
    // For SwiftUI previews, create a fresh CentralViewModel:
    iOSContentView(vm: CentralViewModel())
}

