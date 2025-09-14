import SwiftUI

// === Your exact snapshot view ===
struct CodeaSnapshotView: View {
    /// 0.025 = scoot left by 2.5% of screen width
    var scootLeftByPercentOfScreenWidth: CGFloat = 0.025

    var body: some View {
        GeometryReader { proxy in
            let W = proxy.size.width
            let H = proxy.size.height
            ZStack {
                Color.black.ignoresSafeArea()

                Image("SpartsCodea")
                    .resizable()
                    .frame(width: W, height: H)                 // lock to full screen
                    .offset(x: -scootLeftByPercentOfScreenWidth * W) // slide without resizing
                    .clipped()
                    .ignoresSafeArea()
            }
            .frame(width: W, height: H)
        }
        .ignoresSafeArea()
    }
}


#Preview {
    CodeaSnapshotView()
}
