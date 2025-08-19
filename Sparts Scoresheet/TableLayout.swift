import SwiftUI

// MARK: - Layout Parameters (edit these to tweak bounding boxes)

struct ScoresheetLayoutParams: Equatable {
    // Canvas (page) size in points.
    var pageSize: CGSize = .init(width: 1024, height: 700)

    // Left table (editable hand entries)
    var leftOrigin: CGPoint = .init(x: 0, y: 0)   // top-left of left table
    var leftSize:   CGSize  = .init(width: 10, height: 10)

    // Right table (computed scores / bags / totals)
    var rightOrigin: CGPoint = .init(x: 500, y: 0) // top-left of right table
    var rightSize:   CGSize  = .init(width: 10, height: 10)

    // Borders
    var cornerRadius: CGFloat = 8
    var borderWidth: CGFloat = 1

    // Convenience: distance between tables (read-only)
    var interTableGutter: CGFloat {
        rightOrigin.x - (leftOrigin.x + leftSize.width)
    }
}

// MARK: - Placeholder Boxes (no internals yet)

/// Left-hand table: user-editable bids/results per hand (EMPTY for now; just a bounding box)
struct EntryTableView: View {
    let size: CGSize
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.black.opacity(0.6), lineWidth: borderWidth)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white)
                )
            Text("Hand Entries (editable)")
                .font(.headline)
                .padding(8)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

/// Right-hand table: computed scores/bags/totals (EMPTY for now; just a bounding box)
struct ComputationTableView: View {
    let size: CGSize
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.black.opacity(0.6), lineWidth: borderWidth)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white)
                )
            Text("Computed Scores / Bags / Totals")
                .font(.headline)
                .padding(8)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

// MARK: - Combined Page View (side-by-side composition)

struct ScoresheetPageView: View {
    @State private var params = ScoresheetLayoutParams()

    // Optional: scale-to-fit toggle for smaller devices
    @State private var scaleToFit: Bool = true

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                // Page boundary
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.98))
                    )
                    .frame(width: params.pageSize.width, height: params.pageSize.height)

                // Left table placement
                EntryTableView(size: params.leftSize,
                               cornerRadius: params.cornerRadius,
                               borderWidth: params.borderWidth)
                    .offset(x: params.leftOrigin.x, y: params.leftOrigin.y)

                // Right table placement
                ComputationTableView(size: params.rightSize,
                                     cornerRadius: params.cornerRadius,
                                     borderWidth: params.borderWidth)
                    .offset(x: params.rightOrigin.x, y: params.rightOrigin.y)
            }
            .modifier(ScaleToFitModifier(enabled: scaleToFit, targetSize: params.pageSize))
            .padding(16)
        }
        .safeAreaInset(edge: .bottom) { controls }
    }

    // MARK: - Controls (live tweak knobs)

    private var controls: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle("Scale to fit", isOn: $scaleToFit)
                Spacer()
                Text("Page: \(Int(params.pageSize.width)) × \(Int(params.pageSize.height))")
                Text("Gutter: \(Int(params.interTableGutter))")
            }
            .font(.footnote.monospaced())
            .padding(.horizontal, 12)

            // Page size
            HStack {
                Text("Page W").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.pageSize.width }, set: { params.pageSize.width = $0 }),
                        in: 600...2000, step: 10) { Text("\(Int(params.pageSize.width))") }
                Text("Page H").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.pageSize.height }, set: { params.pageSize.height = $0 }),
                        in: 400...1400, step: 10) { Text("\(Int(params.pageSize.height))") }
                Spacer()
            }
            .font(.footnote.monospaced())
            .padding(.horizontal, 12)

            // Left box
            HStack {
                Text("Left X").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.leftOrigin.x }, set: { params.leftOrigin.x = $0 }),
                        in: 0...1600, step: 2) { Text("\(Int(params.leftOrigin.x))") }
                Text("Left Y").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.leftOrigin.y }, set: { params.leftOrigin.y = $0 }),
                        in: 0...1600, step: 2) { Text("\(Int(params.leftOrigin.y))") }
                Text("Left W").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.leftSize.width }, set: { params.leftSize.width = $0 }),
                        in: 200...1600, step: 5) { Text("\(Int(params.leftSize.width))") }
                Text("Left H").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.leftSize.height }, set: { params.leftSize.height = $0 }),
                        in: 200...1600, step: 5) { Text("\(Int(params.leftSize.height))") }
            }
            .font(.footnote.monospaced())
            .padding(.horizontal, 12)

            // Right box
            HStack {
                Text("Right X").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.rightOrigin.x }, set: { params.rightOrigin.x = $0 }),
                        in: 0...1600, step: 2) { Text("\(Int(params.rightOrigin.x))") }
                Text("Right Y").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.rightOrigin.y }, set: { params.rightOrigin.y = $0 }),
                        in: 0...1600, step: 2) { Text("\(Int(params.rightOrigin.y))") }
                Text("Right W").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.rightSize.width }, set: { params.rightSize.width = $0 }),
                        in: 200...1600, step: 5) { Text("\(Int(params.rightSize.width))") }
                Text("Right H").frame(width: 56, alignment: .leading)
                Stepper(value: bind({ params.rightSize.height }, set: { params.rightSize.height = $0 }),
                        in: 200...1600, step: 5) { Text("\(Int(params.rightSize.height))") }
            }
            .font(.footnote.monospaced())
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            // Borders
            HStack {
                Text("Radius").frame(width: 56, alignment: .leading)
                Stepper(value: $params.cornerRadius, in: 0...24, step: 1) { Text("\(Int(params.cornerRadius))") }
                Text("Border").frame(width: 56, alignment: .leading)
                Stepper(value: $params.borderWidth, in: 0...6, step: 1) { Text("\(Int(params.borderWidth))") }
                Spacer()
            }
            .font(.footnote.monospaced())
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }

    // Helper to bind into nested struct properties (e.g., CGSize.width)
    private func bind<T>(_ get: @escaping () -> T, set: @escaping (T) -> Void) -> Binding<T> {
        Binding(get: get, set: set)
    }
}

// MARK: - Scale-to-fit utility

private struct ScaleToFitModifier: ViewModifier {
    let enabled: Bool
    let targetSize: CGSize

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let sx = geo.size.width  / max(targetSize.width, 1)
            let sy = (geo.size.height - 80) / max(targetSize.height, 1) // leave room for controls
            let s  = enabled ? min(sx, sy) : 1

            VStack(spacing: 0) {
                content
                    .frame(width: targetSize.width, height: targetSize.height)
                    .scaleEffect(s, anchor: .topLeading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScoresheetPageView()
}
