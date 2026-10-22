import SwiftUI

struct PandalPhotoGalleryView: View {
    let photos: [PandalPhoto]
    @State private var selectedPhoto: PandalPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Pandal Gallery")
                    .font(PujaTypography.rounded(17, weight: .bold))
                Spacer()
                Text("\(photos.count) photos")
                    .font(PujaTypography.rounded(11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(photos) { photo in
                        Button { selectedPhoto = photo } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                galleryImage(photo)
                                    .frame(width: 248, height: 166)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                Text(photo.credit.isEmpty ? "Photo credit unavailable" : "Photo: \(photo.credit)")
                                    .font(PujaTypography.rounded(11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 248, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Label("Photos and credits are from the listed source. Reuse permissions have not been verified.",
                  systemImage: "info.circle")
                .font(PujaTypography.rounded(10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(item: $selectedPhoto) { photo in
            PandalPhotoViewer(photo: photo)
        }
    }

    @ViewBuilder
    private func galleryImage(_ photo: PandalPhoto) -> some View {
        if let url = photo.imageURL {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    imagePlaceholder
                        .overlay { ProgressView().tint(PujaColors.goldBright) }
                case .failure:
                    imagePlaceholder
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(PujaColors.goldBright)
                        }
                @unknown default:
                    imagePlaceholder
                }
            }
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(colors: [PujaColors.crimsonVelvet, PujaColors.durgaRed],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image("FestivalEyes")
                .resizable()
                .scaledToFit()
                .padding(24)
                .opacity(0.75)
        }
    }
}

private struct PandalPhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let photo: PandalPhoto

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer(minLength: 12)
                if let url = photo.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .empty:
                            ProgressView().tint(PujaColors.goldBright)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .failure:
                            ContentUnavailableView("Photo unavailable", systemImage: "photo")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if !photo.caption.isEmpty {
                        Text(photo.caption)
                            .font(PujaTypography.rounded(15, weight: .semibold))
                    }
                    Text(photo.credit.isEmpty ? "Credit unavailable" : "Photo: \(photo.credit)")
                        .font(PujaTypography.rounded(12))
                        .foregroundStyle(.secondary)
                    if let source = photo.sourceURL {
                        Link(destination: source) {
                            Label("Open source", systemImage: "arrow.up.right.square")
                                .font(PujaTypography.rounded(12, weight: .semibold))
                        }
                    }
                    Text("Reuse permissions have not been verified.")
                        .font(PujaTypography.rounded(11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .liquidCard(cornerRadius: 18)
            }
            .padding(16)
            .navigationTitle("Pandal Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
