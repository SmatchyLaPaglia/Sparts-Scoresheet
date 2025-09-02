import SwiftUI

import SwiftUI

struct ScoreTableView: View {
    @Binding var hand: Hand
    @State private var leadingSafeArea: CGFloat = 44   // same fallback as DeepSeek's code

    var body: some View {
        ZStack {
            // Dark gray so you can see the screen edges in Simulator
            Color(white: 0.18).ignoresSafeArea()

            // Yellow box that starts exactly at the notch edge and
            // extends to the physical screen edge on the other side.
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.yellow, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.yellow.opacity(0.10))
                )
                .padding(.leading, leadingSafeArea) // EXACTLY hug the island
                .padding(.trailing, 0)
                .padding(.vertical, 0)
        }
        // Use DeepSeek's EXACT mechanism to read the leading safe-area inset.
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        leadingSafeArea = geometry.safeAreaInsets.leading > 0
                        ? geometry.safeAreaInsets.leading
                        : 44
                    }
                    .onChange(of: geometry.size) { _ in
                        leadingSafeArea = geometry.safeAreaInsets.leading > 0
                        ? geometry.safeAreaInsets.leading
                        : 44
                    }
            }
        )
    }
}
// MARK: - Preview
#Preview("Header + 4 Header Duplicates") {
    let team1 = Team(players: [.init(name: "A", bid: nil, took: nil),
                               .init(name: "B", bid: nil, took: nil)],
                     hearts: nil, queenSpades: false, moonShot: false)
    let team2 = Team(players: [.init(name: "C", bid: nil, took: nil),
                               .init(name: "D", bid: nil, took: nil)],
                     hearts: nil, queenSpades: false, moonShot: false)
    return ScoreTableView(hand: .constant(Hand(teams: [team1, team2])))
        .background(Color.black.opacity(0.65))
}
