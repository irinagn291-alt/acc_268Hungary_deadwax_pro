import SwiftUI
import UIKit

/// Role: Square sleeve face. Cover art crops inside the square. The glass plate never stretches to fill a tall tile.
struct SleeveFront: View {
    let urlString: String
    var corner: CGFloat = Bloom.Bend.card
    @State private var image: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    ZStack {
                        Bloom.Pigment.surface
                        face
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .task(id: urlString) {
                await load()
            }
    }

    @ViewBuilder
    private var face: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        } else {
            Image("dwx_CardBackdrop")
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        }
    }

    private func load() async {
        guard let url = URL(string: urlString) else {
            image = nil
            return
        }
        var request = URLRequest(url: url)
        request.setValue(CatalogClient.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200 ... 299).contains(status), let loaded = UIImage(data: data) else {
                image = nil
                return
            }
            image = loaded
        } catch is CancellationError {
            return
        } catch {
            image = nil
        }
    }
}
