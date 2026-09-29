import Combine
import Foundation

@MainActor
final class NewsViewModel {
    @Published private(set) var items: [NewsItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: NewsRepository
    private let pageSize = 15
    private var page = 0
    private var totalCount: Int?

    init(repository: NewsRepository = NewsAPIClient()) {
        self.repository = repository
    }

    func loadInitialPage() async {
        guard items.isEmpty else { return }
        await loadNextPage()
    }

    func loadNextPageIfNeeded(itemID: NewsItem.ID?) async {
        guard let itemID,
              let index = items.firstIndex(where: { $0.id == itemID }),
              index >= items.count - 4 else { return }
        await loadNextPage()
    }

    func retry() async {
        errorMessage = nil
        await loadNextPage()
    }

    private func loadNextPage() async {
        guard !isLoading, totalCount.map({ items.count < $0 }) ?? true else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let nextPage = page + 1
        do {
            let response = try await repository.fetchNews(page: nextPage, pageSize: pageSize)
            page = nextPage
            totalCount = response.totalCount
            var seenIDs = Set(items.map(\.id))
            items.append(contentsOf: response.items.filter { seenIDs.insert($0.id).inserted })
        } catch {
            errorMessage = "Unable to load news. Check your connection and try again."
        }
    }
}
