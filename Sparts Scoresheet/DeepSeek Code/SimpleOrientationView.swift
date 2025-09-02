import SwiftUI

struct SimpleOrientationView: View {
    // The single source of truth for orientation
    @StateObject private var orientationManager = OrientationManager()
    
    var body: some View {
        // Simple logic: Green only for landscapeLeft, Red for everything else
        Group {
            if orientationManager.currentLandscapeDirection == .landscapeRight { // <- CHANGED THIS
                Color.green
            } else {
                Color.red
            }
        }
        .ignoresSafeArea() // Fill the whole screen
    }
}

#Preview {
    // This just shows the live, sensing view.
    // To test, you MUST run the preview in the simulator.
    SimpleOrientationView()
}
