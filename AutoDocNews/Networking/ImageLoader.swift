import UIKit

final class ImageMemoryCache: @unchecked Sendable {
    private let storage: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 256
        cache.totalCostLimit = 384 * 1024 * 1024
        return cache
    }()

    func image(for url: URL) -> UIImage? {
        storage.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        let pixelCount = image.size.width * image.size.height * image.scale * image.scale
        storage.setObject(image, forKey: url as NSURL, cost: Int(pixelCount * 4))
    }
}

actor ImageLoader {
    static let shared = ImageLoader()

    private let session: URLSession
    nonisolated let memoryCache: ImageMemoryCache
    private var inFlightRequests: [URL: Task<UIImage?, Never>] = [:]

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024,
            diskPath: "AutoDocNewsImages"
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        memoryCache = ImageMemoryCache()
    }

    nonisolated func cachedImage(for url: URL) -> UIImage? {
        memoryCache.image(for: url)
    }

    func image(for url: URL) async -> UIImage? {
        guard !Task.isCancelled else { return nil }
        if let cached = memoryCache.image(for: url) { return cached }

        let requestTask: Task<UIImage?, Never>
        if let existingTask = inFlightRequests[url] {
            requestTask = existingTask
        } else {
            requestTask = Task { [session] in
                do {
                    var request = URLRequest(url: url)
                    request.cachePolicy = .returnCacheDataElseLoad
                    let (data, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200..<300).contains(httpResponse.statusCode),
                          httpResponse.mimeType?.hasPrefix("image/") != false else { return nil }
                    return UIImage(data: data)
                } catch {
                    return nil
                }
            }
            inFlightRequests[url] = requestTask
        }

        let image = await requestTask.value
        inFlightRequests[url] = nil
        guard !Task.isCancelled, let image else { return nil }

        memoryCache.insert(image, for: url)
        return image
    }
}
