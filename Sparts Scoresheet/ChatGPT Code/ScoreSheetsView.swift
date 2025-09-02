//
//  ScoreSheetsView.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 8/24/25.
//


// ScoreSheetsView.swift
import SwiftUI

struct ScoreSheetsView: View {
    @StateObject private var vm = ScoreSheetsVM()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.bgApp.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Reset All — above the first sheet and scrolls with it
                    HStack {
                        Button {
                            vm.resetAll()
                        } label: {
                            Text("Reset All")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 120, height: 44)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.resetAllBg))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    ForEach($vm.hands) { $hand in
                        ScoreTableView(hand: $hand)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 80) // breathing room under content
                }
                .padding(.top, 8)
            }

            // Fixed “New Hand” button
            Button {
                vm.addHand()
            } label: {
                Text("New Hand")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.newHandBg))
                    .shadow(radius: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
    }
}