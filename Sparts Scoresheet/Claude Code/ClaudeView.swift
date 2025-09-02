//import SwiftUI
//
//struct ScoringTableView: View {
//    @State private var players = [
//        ScoringPlayer(name: "Lecia", bidTook: "bid/took", spades: "4", hearts: "4", heartsSymbol: "hearts", queen: "queen", moon: "moon"),
//        ScoringPlayer(name: "Arthur", bidTook: "bid/took", spades: "0", hearts: "0", heartsSymbol: "4", queen: "✓", moon: ""),
//        ScoringPlayer(name: "Elena", bidTook: "bid/took", spades: "2", hearts: "5", heartsSymbol: "hearts", queen: "queen", moon: "moon"),
//        ScoringPlayer(name: "Jesse", bidTook: "bid/took", spades: "4", hearts: "4", heartsSymbol: "9", queen: "✓", moon: "")
//    ]
//    
//    @State private var handScores = [
//        ScoringHandScore(spades: "--", hearts: "52", bags: "--"),
//        ScoringHandScore(spades: "140", hearts: "16", bags: "0"),
//        ScoringHandScore(spades: "--", hearts: "--", bags: "--"),
//        ScoringHandScore(spades: "60", hearts: "88", bags: "3")
//    ]
//    
//    @State private var totalScores = [
//        ScoringTotalScore(spades: "--", hearts: "52", bags: "--"),
//        ScoringTotalScore(spades: "140", hearts: "16", bags: "0"),
//        ScoringTotalScore(spades: "--", hearts: "--", bags: "--"),
//        ScoringTotalScore(spades: "60", hearts: "88", bags: "3")
//    ]
//    
//    @State private var gameTotal = "-52"
//    @State private var safeAreaInsets: EdgeInsets = .init()
//    
//    var body: some View {
//        GeometryReader { geometry in
//            let availableWidth = geometry.size.width
//            let leadingPadding = safeAreaInsets.leading > 0 ? safeAreaInsets.leading : 0
//            let tableWidth = availableWidth - leadingPadding
//            
//            VStack(spacing: 0) {
//                // Reset All Button
//                HStack {
//                    Button("Reset All") {
//                        // Reset functionality
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 12)
//                    .background(Color.orange)
//                    .foregroundColor(.white)
//                    .font(.system(size: 16, weight: .medium))
//                    .cornerRadius(4)
//                    
//                    Spacer()
//                }
//                .padding(.bottom, 20)
//                .padding(.leading, leadingPadding)
//                .background(Color.black)
//                
//                // Main Table
//                VStack(spacing: 0) {
//                    // Header Row
//                    HStack(spacing: 0) {
//                        headerCell("TEAMS", width: tableWidth * 0.16)
//                        headerCell("SPADES", width: tableWidth * 0.12)
//                        headerCell("HEARTS", width: tableWidth * 0.12)
//                        headerCell("HAND\nSCORES", width: tableWidth * 0.24)
//                        headerCell("TOTAL\nSCORES", width: tableWidth * 0.24)
//                        headerCell("GRAND\nTOTAL", width: tableWidth * 0.12)
//                    }
//                    
//                    // Sub-header Row
//                    HStack(spacing: 0) {
//                        subHeaderCell("", width: tableWidth * 0.16)
//                        subHeaderCell("", width: tableWidth * 0.12)
//                        subHeaderCell("", width: tableWidth * 0.12)
//                        subHeaderCell("SPADES HEARTS BAGS", width: tableWidth * 0.24)
//                        subHeaderCell("SPADES HEARTS BAGS", width: tableWidth * 0.24)
//                        subHeaderCell("GAME\nTOTAL", width: tableWidth * 0.12)
//                    }
//                    
//                    // Player Rows
//                    ForEach(Array(players.enumerated()), id: \.offset) { index, player in
//                        HStack(spacing: 0) {
//                            playerNameCell(player.name, width: tableWidth * 0.16)
//                            
//                            // Bid/Took section
//                            VStack(spacing: 0) {
//                                bidTookCell(player.bidTook, width: tableWidth * 0.12)
//                                bidTookCell(player.spades, width: tableWidth * 0.12, isBlue: true)
//                            }
//                            
//                            // Hearts section
//                            VStack(spacing: 0) {
//                                bidTookCell(player.hearts, width: tableWidth * 0.12)
//                                bidTookCell(player.heartsSymbol, width: tableWidth * 0.12, isBlue: true)
//                            }
//                            
//                            // Hand Scores
//                            if index < handScores.count {
//                                handScoreSection(handScores[index], width: tableWidth * 0.24)
//                            } else {
//                                handScoreSection(ScoringHandScore(spades: "--", hearts: "--", bags: "--"), width: tableWidth * 0.24)
//                            }
//                            
//                            // Total Scores
//                            if index < totalScores.count {
//                                totalScoreSection(totalScores[index], width: tableWidth * 0.24)
//                            } else {
//                                totalScoreSection(ScoringTotalScore(spades: "--", hearts: "--", bags: "--"), width: tableWidth * 0.24)
//                            }
//                            
//                            // Game Total
//                            if index == 1 { // Arthur's row
//                                gameTotalCell("156", width: tableWidth * 0.12)
//                            } else if index == 3 { // Jesse's row
//                                gameTotalCell("148", width: tableWidth * 0.12)
//                            } else {
//                                gameTotalCell("--", width: tableWidth * 0.12)
//                            }
//                        }
//                        .background(index % 2 == 0 ? Color.gray.opacity(0.1) : Color.clear)
//                    }
//                }
//                .padding(.leading, leadingPadding)
//                .background(Color.black)
//                
//                Spacer()
//                
//                // Bottom Buttons
//                HStack {
//                    // Spades icon button (left)
//                    Button(action: {}) {
//                        Image(systemName: "suit.spade.fill")
//                            .foregroundColor(.green)
//                            .font(.title2)
//                    }
//                    .frame(width: 60, height: 60)
//                    .background(Color.gray.opacity(0.3))
//                    .cornerRadius(8)
//                    
//                    Spacer()
//                    
//                    // New Hand button
//                    Button("New Hand") {
//                        // New hand functionality
//                    }
//                    .padding(.horizontal, 30)
//                    .padding(.vertical, 15)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .font(.system(size: 18, weight: .medium))
//                    .cornerRadius(8)
//                }
//                .padding(.horizontal, 20)
//                .padding(.bottom, 20)
//                .padding(.leading, leadingPadding)
//                .background(Color.black)
//            }
//            .background(Color.black)
//            .onAppear {
//                safeAreaInsets = geometry.safeAreaInsets
//            }
//            .onChange(of: geometry.size) { _ in
//                safeAreaInsets = geometry.safeAreaInsets
//            }
//        }
//        .ignoresSafeArea(.all)
//    }
//    
//    private func headerCell(_ text: String, width: CGFloat) -> some View {
//        Text(text)
//            .font(.system(size: 14, weight: .bold))
//            .foregroundColor(.orange)
//            .frame(width: width, height: 50)
//            .background(Color.gray.opacity(0.8))
//            .border(Color.gray.opacity(0.5), width: 0.5)
//    }
//    
//    private func subHeaderCell(_ text: String, width: CGFloat) -> some View {
//        Text(text)
//            .font(.system(size: 12, weight: .medium))
//            .foregroundColor(.orange)
//            .frame(width: width, height: 30)
//            .background(Color.gray.opacity(0.6))
//            .border(Color.gray.opacity(0.5), width: 0.5)
//    }
//    
//    private func playerNameCell(_ name: String, width: CGFloat) -> some View {
//        Text(name)
//            .font(.system(size: 16, weight: .medium))
//            .foregroundColor(.white)
//            .frame(width: width, height: 80)
//            .background(Color.gray.opacity(0.3))
//            .border(Color.gray.opacity(0.5), width: 0.5)
//    }
//    
//    private func bidTookCell(_ text: String, width: CGFloat, isBlue: Bool = false) -> some View {
//        Text(text)
//            .font(.system(size: 12))
//            .foregroundColor(isBlue ? .blue : .gray)
//            .frame(width: width, height: 40)
//            .background(Color.gray.opacity(0.8))
//            .border(Color.gray.opacity(0.5), width: 0.5)
//    }
//    
//    private func handScoreSection(_ score: ScoringHandScore, width: CGFloat) -> some View {
//        HStack(spacing: 0) {
//            scoreCell(score.spades, backgroundColor: .teal, width: width/3)
//            scoreCell(score.hearts, backgroundColor: .cyan, width: width/3)
//            scoreCell(score.bags, backgroundColor: .teal, width: width/3)
//        }
//    }
//    
//    private func totalScoreSection(_ score: ScoringTotalScore, width: CGFloat) -> some View {
//        HStack(spacing: 0) {
//            scoreCell(score.spades, backgroundColor: .blue.opacity(0.8), width: width/3)
//            scoreCell(score.hearts, backgroundColor: .blue, width: width/3)
//            scoreCell(score.bags, backgroundColor: .blue.opacity(0.6), width: width/3)
//        }
//    }
//    
//    private func scoreCell(_ text: String, backgroundColor: Color, width: CGFloat) -> some View {
//        Text(text)
//            .font(.system(size: 14, weight: .medium))
//            .foregroundColor(.white)
//            .frame(width: width, height: 80)
//            .background(backgroundColor)
//            .border(Color.gray.opacity(0.3), width: 0.5)
//    }
//    
//    private func gameTotalCell(_ text: String, width: CGFloat) -> some View {
//        Text(text)
//            .font(.system(size: 16, weight: .bold))
//            .foregroundColor(.white)
//            .frame(width: width, height: 80)
//            .background(Color.purple.opacity(0.8))
//            .border(Color.gray.opacity(0.5), width: 0.5)
//    }
//}
//
//struct ScoringPlayer {
//    let name: String
//    let bidTook: String
//    let spades: String
//    let hearts: String
//    let heartsSymbol: String
//    let queen: String
//    let moon: String
//}
//
//struct ScoringHandScore {
//    let spades: String
//    let hearts: String
//    let bags: String
//}
//
//struct ScoringTotalScore {
//    let spades: String
//    let hearts: String
//    let bags: String
//}
//
//#Preview {
//    ScoringTableView()
//}
