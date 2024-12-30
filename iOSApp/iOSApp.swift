import SwiftUI
import WidgetKit
import HealthKit

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // 1) Store whether onboarding is complete
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @StateObject private var viewModel = CentralViewModel()
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                // 2) Show your main view if onboarding is finished
                iOSContentView(vm: viewModel)
            } else {
                // 3) Otherwise, show the onboarding flow
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding, vm: viewModel)
            }
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
            VStack {
                CalendarView(viewModel: vm)
                
                Button("Sync") {
                    Task {
                        await vm.refresh()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
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

