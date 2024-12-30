import SwiftUI

struct SyncCompletedToast: View {
    // This state controls whether the toast is on-screen or not
    @State private var isVisible = false
    
    // Callback when we want to remove the toast from the parent.
    var onHide: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Health and Calendar Sync Completed")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(radius: 4)
                // Start *farther* off the bottom of the screen:
                .offset(y: isVisible ? 0 : 300)
                // Animate changes to offset
                .animation(.easeInOut(duration: 0.3), value: isVisible)
                .onAppear {
                    // Slide in the toast
                    isVisible = true
                    
                    // Dismiss automatically after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isVisible = false
                        }
                        // Wait until the slide-out animation finishes:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onHide()
                        }
                    }
                }
        }
        .padding(.bottom, 40)
    }
}
