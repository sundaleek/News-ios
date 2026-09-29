import Foundation

protocol NewsRepository: Sendable {
    func fetchNews(page: Int, pageSize: Int) async throws -> NewsPage
}

struct NewsPage: Sendable {
    let items: [NewsItem]
    let totalCount: Int
}

struct NewsAPIClient: NewsRepository {
    private let session: URLSession

    private static let baseURL = URL(string: "https://webapi.autodoc.ru/api/news")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchNews(page: Int, pageSize: Int) async throws -> NewsPage {
        guard page > 0, pageSize > 0 else { throw URLError(.badURL) }

        let url = Self.baseURL
            .appendingPathComponent(String(page))
            .appendingPathComponent(String(pageSize))
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let responseBody = try JSONDecoder().decode(NewsResponse.self, from: data)
        return NewsPage(items: responseBody.news, totalCount: responseBody.totalCount)
    }
}

private struct NewsResponse: Decodable {
    let news: [NewsItem]
    let totalCount: Int
}
