//
//  ContentViewV2.swift
//  Sparts Scoresheet
//
//  Created by Jesse Wonder Clark on 8/19/25.
//

import SwiftUI

@main
struct Sparts_ScoresheetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// A single table cell used by the score sheet.
struct ScoreCell: View {
    let text: String
    let background: Color
    let width: CGFloat

    var body: some View {
        Text(text)
            .frame(width: width, height: 40, alignment: .center)
            .background(background)
            .border(Color.black, width: 1)
    }
}

/// Displays the score sheet matching the supplied mockup.
struct ContentView: View {

    struct Player: Identifiable {
        let id = UUID()
        let round: String
        let name: String
        let spades: String
        let hearts: String
        let spadesScore: String
        let handScore: String
        let handBags: String
        let allBags: String
        let spadesTotal: String
        let heartsTotal: String
        let gameTotal: String
    }

    /// Static data that mirrors the screen shot.
    private let players: [Player] = [
        Player(round: "1", name: "Leila", spades: "4 2", hearts: "4 ♥️ queen", spadesScore: "60", handScore: "72", handBags: "12", allBags: "0", spadesTotal: "60", heartsTotal: "72", gameTotal: "-12"),
        Player(round: "", name: "Arthur", spades: "2 5", hearts: "5 ☑️", spadesScore: "40", handScore: "32", handBags: "8", allBags: "3", spadesTotal: "40", heartsTotal: "32", gameTotal: "8"),
        Player(round: "", name: "Elena", spades: "7", hearts: "7 ♥️ moon", spadesScore: "0", handScore: "32", handBags: "8", allBags: "3", spadesTotal: "0", heartsTotal: "32", gameTotal: "8"),
        Player(round: "", name: "Jesse", spades: "0 8", hearts: "", spadesScore: "", handScore: "", handBags: "", allBags: "", spadesTotal: "", heartsTotal: "", gameTotal: "")
    ]

    // Column widths derived from the provided layout.
    private let roundWidth: CGFloat = 24
    private let memberWidth: CGFloat = 110
    private let spadesWidth: CGFloat = 60
    private let heartsWidth: CGFloat = 120
    private let scoreWidth: CGFloat = 80
    private let bagsWidth: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ScoreCell(text: "", background: .clear, width: roundWidth)
                ScoreCell(text: "TEAM\nMEMBER", background: Color(white: 0.8), width: memberWidth)
                ScoreCell(text: "SPADES", background: Color(white: 0.8), width: spadesWidth)
                ScoreCell(text: "HEARTS", background: Color(white: 0.8), width: heartsWidth)
                ScoreCell(text: "SPADES\nSCORE", background: Color(red: 0.57, green: 0.74, blue: 0.72), width: scoreWidth)
                ScoreCell(text: "HAND\nSCORE", background: Color(red: 0.53, green: 0.54, blue: 0.55), width: scoreWidth)
                ScoreCell(text: "HAND\nBAGS", background: Color(red: 0.31, green: 0.60, blue: 0.83), width: bagsWidth)
                ScoreCell(text: "ALL\nBAGS", background: Color(white: 0.88), width: bagsWidth)
                ScoreCell(text: "SPADES\nTOTAL", background: Color(red: 0.80, green: 0.32, blue: 0.60), width: scoreWidth)
                ScoreCell(text: "HEARTS\nTOTAL", background: Color(red: 0.94, green: 0.29, blue: 0.47), width: scoreWidth)
                ScoreCell(text: "GAME\nTOTAL", background: Color(red: 0.55, green: 0.43, blue: 0.56), width: scoreWidth)
            }

            ForEach(players) { player in
                HStack(spacing: 0) {
                    ScoreCell(text: player.round, background: .clear, width: roundWidth)
                    ScoreCell(text: player.name, background: .white, width: memberWidth)
                    ScoreCell(text: player.spades, background: .white, width: spadesWidth)
                    ScoreCell(text: player.hearts, background: .white, width: heartsWidth)
                    ScoreCell(text: player.spadesScore, background: Color(red: 0.57, green: 0.74, blue: 0.72), width: scoreWidth)
                    ScoreCell(text: player.handScore, background: Color(red: 0.53, green: 0.54, blue: 0.55), width: scoreWidth)
                    ScoreCell(text: player.handBags, background: Color(red: 0.31, green: 0.60, blue: 0.83), width: bagsWidth)
                    ScoreCell(text: player.allBags, background: Color(white: 0.88), width: bagsWidth)
                    ScoreCell(text: player.spadesTotal, background: Color(red: 0.80, green: 0.32, blue: 0.60), width: scoreWidth)
                    ScoreCell(text: player.heartsTotal, background: Color(red: 0.94, green: 0.29, blue: 0.47), width: scoreWidth)
                    ScoreCell(text: player.gameTotal, background: Color(red: 0.55, green: 0.43, blue: 0.56), width: scoreWidth)
                }
            }
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.black)
    }
}

#Preview {
    ContentView()
}
