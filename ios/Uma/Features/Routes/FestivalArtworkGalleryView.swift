import SwiftUI

private struct FestivalArtwork: Identifiable {
    let imageName: String
    let title: String
    var id: String { imageName }
}

struct FestivalArtworkGalleryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let artwork: [FestivalArtwork] = [
        .init(imageName: "PujaHeritage", title: "Heritage courtyards"),
        .init(imageName: "PujaModern", title: "Contemporary pandals"),
        .init(imageName: "PujaLights", title: "A city of lights"),
        .init(imageName: "PujaMorning", title: "Morning offerings"),
        .init(imageName: "PujaArtisan", title: "Kumartuli craftsmanship"),
        .init(imageName: "PujaWelcome", title: "The festival at night"),
        .init(imageName: "PujaDhunuchi", title: "Dhunuchi rhythm"),
        .init(imageName: "PujaBonedi", title: "Bonedi Puja"),
        .init(imageName: "PujaDhak", title: "The sound of the dhak"),
        .init(imageName: "PujaFood", title: "Festival flavours"),
        .init(imageName: "PujaVisarjan", title: "A farewell by the river")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text("Festival scenes")
                    .font(PujaTypography.rounded(17, weight: .bold))
                Spacer()
                Text("OFFLINE ILLUSTRATIONS")
                    .font(PujaTypography.rounded(9, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(artwork) { item in
                        ZStack(alignment: .bottomLeading) {
                            Image(item.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 244, height: 156)
                                .clipped()
                            LinearGradient(colors: [.clear, .black.opacity(0.72)],
                                           startPoint: .center, endPoint: .bottom)
                            Label(item.title, systemImage: "sparkles")
                                .font(PujaTypography.rounded(13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(PujaColors.festivalGold.opacity(0.35), lineWidth: 1))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Original offline illustration: \(item.title)")
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(reduceMotion || phase.isIdentity ? 1 : 0.96)
                                .opacity(reduceMotion || phase.isIdentity ? 1 : 0.84)
                        }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
}
