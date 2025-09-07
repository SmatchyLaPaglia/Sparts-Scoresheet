//
//  BakeBezelView.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 9/6/25.
//


import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct BakeBezelView: View {
    @State private var baked: UIImage?
    @State private var status: String = "Ready"

    // Tunables
    @State private var pixelSide: Int = 4096        // final PNG size (large, crisp)
    @State private var innerRatio: CGFloat = 0.70   // hole size (0.0–0.95)
    @State private var marginPx: CGFloat = 24       // outer inset in pixels
    @State private var angle: CGFloat = 0           // radians rotation

    var body: some View {
        VStack(spacing: 16) {
            Text(status).font(.footnote).foregroundStyle(.secondary)

            if let img = baked {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320, maxHeight: 320)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle().fill(.black.opacity(0.1))
                    .frame(width: 240, height: 240)
                    .overlay(Text("No render yet"))
            }

            HStack {
                Button("Bake 4K") { Task { await bakeAndSave() } }
                    .buttonStyle(.borderedProminent)
                Button("Open Documents") { openDocuments() }
            }
        }
        .padding()
        .onAppear { Task { await bakeAndSave(previewOnly: true) } }
    }

    // MARK: - Baking

    func bakeAndSave(previewOnly: Bool = false) async {
        guard let srcCG = UIImage(named: "mercator-detailed")?.cgImage else {
            status = "Missing mercator-detailed asset"; return
        }
        do {
            status = "Rendering…"
            let cg = try await renderAnnulusCI(
                source: srcCG,
                side: pixelSide,
                innerRatio: innerRatio,
                margin: marginPx,
                angle: angle
            )
            let ui = UIImage(cgImage: cg)
            baked = ui

            guard !previewOnly, let data = ui.pngData() else {
                status = "Preview ready"; return
            }
            let url = try documentsURL().appendingPathComponent(
                String(format: "bezel_%dx%d_ir%.3f_m%.0f_a%.2f.png",
                       pixelSide, pixelSide, innerRatio, marginPx, angle)
            )
            try data.write(to: url, options: .atomic)
            status = "Saved → \(url.lastPathComponent)"
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Core Image warp (rect → annulus)

    func renderAnnulusCI(
        source: CGImage,
        side: Int,
        innerRatio: CGFloat,
        margin: CGFloat,
        angle: CGFloat
    ) async throws -> CGImage {
        let ci = CIImage(cgImage: source)
        let kernelSrc = """
        kernel vec4 mercatorToRing(sampler src,
                                   float cx, float cy,
                                   float innerR, float outerR,
                                   float angleOffset)
        {
            vec2 dc = destCoord();
            vec2 d  = dc - vec2(cx, cy);
            float r = length(d);
            if (r < innerR || r > outerR) { return vec4(0.0); }

            float th = atan2(d.y, d.x) + angleOffset;
            float u = (th + M_PI) / (2.0 * M_PI);
            u = fract(u);

            float t = (r - innerR) / (outerR - innerR);
            float vTex = 1.0 - t;

            float sx = u * samplerSize(src).x;
            float sy = vTex * samplerSize(src).y;
            return sample(src, vec2(sx, sy));
        }
        """
        guard let kernel = try? CIColorKernel(source: kernelSrc) else {
            throw NSError(domain: "BezelBake", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kernel compile failed"])
        }

        let dim = CGFloat(side)
        let extent = CGRect(x: 0, y: 0, width: dim, height: dim)
        let outerR = dim * 0.5 - margin
        let innerR = max(0, outerR * innerRatio)
        let center = CGPoint(x: dim/2, y: dim/2)

        guard let output = kernel.apply(
            extent: extent,
            arguments: [ci, center.x, center.y, innerR, outerR, angle]
        ) else {
            throw NSError(domain: "BezelBake", code: 2, userInfo: [NSLocalizedDescriptionKey: "Kernel apply failed"])
        }

        // High-quality CI render
        let ctx = CIContext(options: [
            .useSoftwareRenderer: false,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ])
        guard let cg = ctx.createCGImage(output, from: extent) else {
            throw NSError(domain: "BezelBake", code: 3, userInfo: [NSLocalizedDescriptionKey: "CIContext createCGImage failed"])
        }
        return cg
    }

    // MARK: - Files helpers

    func documentsURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    func openDocuments() {
        // Handy during simulator testing: prints sandbox path
        if let url = try? documentsURL() {
            print("Documents:", url.path)
        }
    }
}
