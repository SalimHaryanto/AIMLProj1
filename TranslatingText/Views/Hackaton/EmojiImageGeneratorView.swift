// EmojiImageGeneratorView.swift
// Creates images using the (hypothetical) ImagePlayground framework and shows them in a scrollable sheet.

import SwiftUI
import ImagePlayground

struct EmojiImageGeneratorView: View {
    let emojis: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var generatedImages: [GeneratedItem] = []
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil

    struct GeneratedItem: Identifiable {
        let id = UUID()
        let emoji: String
        let uiImage: UIImage
    }

    var body: some View {
        NavigationView {
            Group {
                if isGenerating {
                    ProgressView("Generating images...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if generatedImages.isEmpty {
                    ContentUnavailableView("No images yet", systemImage: "photo")
                }
                else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                }
                else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(groupedByEmoji(), id: \.0) { emoji, items in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(emoji)
                                        .font(.largeTitle)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(items) { item in
                                                Image(uiImage: item.uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 180, height: 180)
                                                    .clipped()
                                                    .cornerRadius(12)
                                                    .shadow(radius: 2)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Generated Images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Regenerate") { Task { await generateAllWithImagePlayground() } }
                        .disabled(isGenerating)
                }
            }
            .task { await generateAllWithImagePlayground() }
        }
    }

    private func groupedByEmoji() -> [(String, [GeneratedItem])] {
        let dict = Dictionary(grouping: generatedImages, by: { $0.emoji })
        return emojis.map { ($0, dict[$0] ?? []) }
    }

    private func generateAllWithImagePlayground() async {
        isGenerating = true
        errorMessage = nil
        generatedImages.removeAll()

        #if canImport(ImagePlayground)
        do {
            let imageCreator = try await ImageCreator()
            // For each emoji, request 2 images by varying a style hint in the prompt.
            for emoji in emojis {
                for variant in 0..<2 {
                    let prompt = "Create a high-quality illustration inspired by the emoji \(emoji), style variant \(variant)."
                    let images = imageCreator.images(
                        for: [.text(prompt)],
                        style: .sketch,
                        limit: 1
                    )
                    for try await image in images {
                        await MainActor.run {
                            generatedImages.append(GeneratedItem(emoji: emoji, uiImage: UIImage(cgImage: image.cgImage)))
                        }
                    }
                }
            }
        } catch ImageCreator.Error.notSupported {
            await MainActor.run { errorMessage = "Image creation isn’t supported on this device." }
        } catch {
            await MainActor.run { errorMessage = "Failed to generate images: \(error.localizedDescription)" }
        }
        #else
        // Fallback: if ImagePlayground isn't available, keep the previous renderer behavior
        for emoji in emojis {
            for idx in 0..<2 {
                if let image = await generateImage(for: emoji, variation: idx) {
                    await MainActor.run {
                        generatedImages.append(GeneratedItem(emoji: emoji, uiImage: image))
                    }
                }
            }
        }
        #endif

        await MainActor.run { isGenerating = false }
    }

    private func generateImage(for emoji: String, variation: Int) async -> UIImage? {
        // Reference implementation: render the emoji into a stylized image.
        // Two variations are produced by changing background gradient, overlay, and shadow.
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)

            // Background style per variation
            switch variation % 2 {
            case 0:
                // Variation A: radial gradient background
                let colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                    ctx.cgContext.drawRadialGradient(
                        gradient,
                        startCenter: CGPoint(x: rect.midX, y: rect.midY), startRadius: 10,
                        endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: max(rect.width, rect.height)/1.2,
                        options: [.drawsAfterEndLocation]
                    )
                } else {
                    UIColor.systemTeal.setFill(); ctx.fill(rect)
                }
            default:
                // Variation B: linear gradient background
                let colors = [UIColor.systemPink.cgColor, UIColor.systemOrange.cgColor]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                    ctx.cgContext.drawLinearGradient(
                        gradient,
                        start: CGPoint(x: 0, y: 0),
                        end: CGPoint(x: rect.maxX, y: rect.maxY),
                        options: []
                    )
                } else {
                    UIColor.systemOrange.setFill(); ctx.fill(rect)
                }
            }

            // Draw a subtle rounded-rect card
            let insetRect = rect.insetBy(dx: 24, dy: 24)
            let path = UIBezierPath(roundedRect: insetRect, cornerRadius: 28)
            UIColor.white.withAlphaComponent(0.15).setFill()
            path.fill()

            // Emoji attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 220),
                .shadow: {
                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = variation % 2 == 0 ? 16 : 6
                    shadow.shadowOffset = CGSize(width: 0, height: variation % 2 == 0 ? 8 : 3)
                    shadow.shadowColor = UIColor.black.withAlphaComponent(variation % 2 == 0 ? 0.35 : 0.2)
                    return shadow
                }()
            ]

            // Center the emoji
            let str = emoji as NSString
            let size = str.size(withAttributes: attributes)
            let drawRect = CGRect(
                x: rect.midX - size.width/2,
                y: rect.midY - size.height/2,
                width: size.width,
                height: size.height
            )
            str.draw(in: drawRect, withAttributes: attributes)

            // Foreground flourish per variation
            if variation % 2 == 0 {
                // Light beams
                ctx.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.25).cgColor)
                ctx.cgContext.setLineWidth(6)
                for angle in stride(from: 0.0, through: .pi * 2, by: .pi / 6) {
                    let r: CGFloat = 220
                    let start = CGPoint(x: rect.midX + cos(angle) * 40, y: rect.midY + sin(angle) * 40)
                    let end = CGPoint(x: rect.midX + cos(angle) * r, y: rect.midY + sin(angle) * r)
                    ctx.cgContext.move(to: start)
                    ctx.cgContext.addLine(to: end)
                    ctx.cgContext.strokePath()
                }
            } else {
                // Bokeh circles
                for _ in 0..<12 {
                    let radius = CGFloat.random(in: 16...44)
                    let x = CGFloat.random(in: radius...(rect.width - radius))
                    let y = CGFloat.random(in: radius...(rect.height - radius))
                    let circle = UIBezierPath(ovalIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    UIColor.white.withAlphaComponent(0.12).setFill()
                    circle.fill()
                }
            }
        }
        return img
    }
}

#Preview {
    EmojiImageGeneratorView(emojis: ["😀", "🐶", "🌸"])    
}
