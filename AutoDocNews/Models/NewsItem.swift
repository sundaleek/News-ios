import Foundation

struct NewsItem: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let text: String
    let imageURL: URL?
    let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, text, description, image, imageUrl, imageURL, titleImageUrl
        case publishedAt, publishedDate, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawID = try? container.decode(String.self, forKey: .id)
        let numericID = try? container.decode(Int.self, forKey: .id)
        id = rawID ?? numericID.map(String.init) ?? UUID().uuidString
        title = (try? container.decode(String.self, forKey: .title)) ?? "Untitled news"
        text = (try? container.decode(String.self, forKey: .description))
            ?? (try? container.decode(String.self, forKey: .text))
            ?? ""
        let imageString = (try? container.decode(String.self, forKey: .titleImageUrl))
            ?? (try? container.decode(String.self, forKey: .imageUrl))
            ?? (try? container.decode(String.self, forKey: .imageURL))
            ?? (try? container.decode(String.self, forKey: .image))
        imageURL = imageString.flatMap(URL.init(string:))
        publishedAt = (try? container.decode(String.self, forKey: .publishedDate))
            ?? (try? container.decode(String.self, forKey: .publishedAt))
            ?? (try? container.decode(String.self, forKey: .date))
    }
}
