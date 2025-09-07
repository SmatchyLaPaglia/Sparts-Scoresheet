import SwiftUI

import SwiftUI

struct PercentCanvas<Content: View>: View {
    let size: CGSize                    // usually safeRect.size
    @ViewBuilder var content: (CGSize) -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            content(size)               // draw in this size’s coordinate space
                .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

// MARK: - Theme (minimal)
enum ThemeX {
    static let gridLine        = Color.gray.opacity(0.35)
    static let leftHeaderText  = Color.orange
    static let leftHeaderBg    = Color(red: 0.20, green: 0.20, blue: 0.20)
}

// MARK: - Percent helpers (Codea-style 0..100 on the design surface)
enum DS {
    static func px(_ pct: CGFloat, in size: CGSize) -> CGFloat { size.width  * pct / 100 }
    static func py(_ pct: CGFloat, in size: CGSize) -> CGFloat { size.height * pct / 100 }
    static func rectPct(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, in size: CGSize) -> CGRect {
        CGRect(x: px(x, in: size),
               y: py(y, in: size),
               width:  size.width  * w / 100,
               height: size.height * h / 100)
    }
}

// MARK: - Codea-style cell (_cell) as a view
struct CellView: View {
    let x, y, w, h: CGFloat
    let bg: Color
    var txt: String? = nil
    var txtCol: Color = ThemeX.leftHeaderText
    var fsz: CGFloat? = nil

    var body: some View {
        ZStack {
            Rectangle()
                .fill(bg)
                .overlay(Rectangle().stroke(ThemeX.gridLine, lineWidth: 1))

            if let text = txt {
                Text(text)
                    .font(Font(UIFont(name: "HelveticaNeue-Bold",
                                      size: fsz ?? (h * 0.45)) ?? .boldSystemFont(ofSize: fsz ?? (h * 0.45))))
                    .foregroundColor(txtCol)
                    .multilineTextAlignment(.center)
                    .frame(width: w, height: h)
            }
        }
        .frame(width: w, height: h)
        .position(x: x + w/2, y: y + h/2)   // CORNER mode + centered text
    }
}

import SwiftUI

struct DesignSpaceInRect<Content: View>: View {
    let designSize: CGSize          // your logical canvas (e.g. 1000x600)
    let containerSize: CGSize       // the safeRect.size from NotchSafeView
    @ViewBuilder var content: (CGSize) -> Content  // gets designSize coords

    var body: some View {
        let scale = min(containerSize.width / designSize.width,
                        containerSize.height / designSize.height)

        ZStack(alignment: .topLeading) {
            content(designSize) // draw in *design* coords, top-left origin
                .frame(width: designSize.width, height: designSize.height, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
        }
        .frame(width: containerSize.width, height: containerSize.height, alignment: .topLeading)
    }
}

// MARK: - DesignSpace
/// A fixed logical canvas (e.g. 1000x600) that is scaled to fit the device,
/// centered, and keeps a top-left origin to match Codea math.
struct DesignSpace<Content: View>: View {
    let designSize: CGSize
    @ViewBuilder var content: (CGSize) -> Content

    init(designSize: CGSize, @ViewBuilder content: @escaping (CGSize) -> Content) {
        self.designSize = designSize
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let safe = geo.size
            let scale = min(safe.width / designSize.width,
                            safe.height / designSize.height)
            let canvasW = designSize.width * scale
            let canvasH = designSize.height * scale
            let originX = (safe.width  - canvasW) / 2
            let originY = (safe.height - canvasH) / 2

            ZStack(alignment: .topLeading) {
                Color.clear

                content(designSize) // <- all drawing uses *design* coords
                    .frame(width: designSize.width, height: designSize.height, alignment: .topLeading)
                    .scaleEffect(scale, anchor: .topLeading)
                    .offset(x: originX, y: originY) // center the scaled canvas
            }
            .frame(width: safe.width, height: safe.height, alignment: .topLeading)
        }
        .ignoresSafeArea() // so geometry is full-screen
    }
}

// MARK: - Grid overlay (debug)
struct DesignGrid: View {
    let size: CGSize
    let step: CGFloat // in design points

    var body: some View {
        Canvas { ctx, _ in
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width + 0.5 {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height + 0.5 {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            ctx.stroke(path, with: .color(ThemeX.gridLine), lineWidth: 10)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

// MARK: - Proof view (percent placement)
struct DesignSpaceProof: View {
    let designSize = CGSize(width: 1000, height: 600) // pick any fixed logical size

    var body: some View {
        DesignSpace(designSize: designSize) { size in
            ZStack(alignment: .topLeading) {
                // Visualize the design surface
                DesignGrid(size: size, step: size.width / 20) // 5% grid
                    .overlay(alignment: .topLeading) {
                        Rectangle().frame(height: 4).foregroundStyle(Color.red.opacity(0.8))
                    }

                // --- PROOF #1: (50%, 50%) center ---
                // Use CORNER rect; to center it on (50,50), subtract half w/h.
                let cw = size.width * 0.10
                let ch = size.height * 0.08
                let cx = DS.px(50, in: size) - cw/2
                let cy = DS.py(50, in: size) - ch/2
                CellView(x: cx, y: cy, w: cw, h: ch, bg: .clear, txt: "CENTER")

                // --- PROOF #2: (0%, 50%) left-middle ---
                let lw = cw
                let lh = ch
                let lx = DS.px(0, in: size)
                let ly = DS.py(50, in: size) - lh/2
                CellView(x: lx, y: ly, w: lw, h: lh, bg: .clear, txt: "LEFT MID")

                // Example header cell at 10%/10% width/height (optional)
                let header = DS.rectPct(10, 15, 12, 7, in: size)
                CellView(x: header.minX, y: header.minY,
                         w: header.width, h: header.height,
                         bg: ThemeX.leftHeaderBg, txt: "TEAMS")
            }
        }
        .background(Color.white)
        .preferredColorScheme(.light)
    }
}

#Preview("Canvas in NotchSafeView", traits: .landscapeLeft) {
    NotchSafeView(heightPercent: 100,
                  paddingPercentNotchSide: 0,
                  paddingPercentSideOppositeNotch: 0) { safeRect in
        PercentCanvas(size: safeRect.size) { size in
            // DEBUG outline: should hug the purple panel exactly
            Rectangle().stroke(.red, lineWidth: 2)
                .frame(width: size.width, height: size.height)

            // Proofs:
            let cw = size.width * 0.10
            let ch = size.height * 0.08

            // (50%, 50%) centered
            let cx = DS.px(50, in: size) - cw/2
            let cy = DS.py(50, in: size) - ch/2
            CellView(x: cx, y: cy, w: cw, h: ch, bg: .clear, txt: "CENTER")

            // (0%, 50%) left-middle
            let lx = DS.px(0, in: size)
            let ly = DS.py(50, in: size) - ch/2
            CellView(x: lx, y: ly, w: cw, h: ch, bg: .clear, txt: "LEFT MID")
        }
    }
}
