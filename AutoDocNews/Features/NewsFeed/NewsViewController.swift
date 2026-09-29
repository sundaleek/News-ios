import Combine
import UIKit

@MainActor
final class NewsViewController: UIViewController {
    private enum Section { case main }

    private let viewModel = NewsViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let emptyStateView = NewsFeedStatusView(style: .empty)
    private let paginationStatusView = NewsFeedStatusView(style: .inline)
    private let cellRegistration = UICollectionView.CellRegistration<NewsCell, NewsItem> { cell, _, item in
        cell.configure(with: item)
    }
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: Self.makeLayout()
    )
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, NewsItem>(
        collectionView: collectionView
    ) { [weak self] collectionView, indexPath, item in
        guard let self else { return nil }
        return collectionView.dequeueConfiguredReusableCell(
            using: self.cellRegistration,
            for: indexPath,
            item: item
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "News"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        configureCollectionView()
        bindViewModel()
        Task { [viewModel] in
            await viewModel.loadInitialPage()
        }
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.backgroundView = emptyStateView
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        paginationStatusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paginationStatusView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            paginationStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paginationStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paginationStatusView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            paginationStatusView.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let width = environment.container.effectiveContentSize.width
            let columnCount = width >= 1_000 ? 3 : width >= 640 ? 2 : 1
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / CGFloat(columnCount)),
                heightDimension: .estimated(400)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(400)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: columnCount
            )
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16)
            return section
        }
    }

    private func bindViewModel() {
        Publishers.CombineLatest3(viewModel.$items, viewModel.$isLoading, viewModel.$errorMessage)
            .receive(on: RunLoop.main)
            .sink { [weak self] items, isLoading, errorMessage in
                guard let self else { return }
                self.renderStatus(items: items, isLoading: isLoading, errorMessage: errorMessage)
                var snapshot = NSDiffableDataSourceSnapshot<Section, NewsItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items)
                self.dataSource.apply(
                    snapshot,
                    animatingDifferences: !self.dataSource.snapshot().itemIdentifiers.isEmpty
                )
            }
            .store(in: &cancellables)
    }

    private func renderStatus(items: [NewsItem], isLoading: Bool, errorMessage: String?) {
        let retry: () -> Void = { [viewModel] in
            Task { await viewModel.retry() }
        }

        emptyStateView.render(
            isLoading: items.isEmpty && isLoading,
            message: items.isEmpty ? errorMessage : nil,
            onRetry: retry
        )
        paginationStatusView.render(
            isLoading: !items.isEmpty && isLoading,
            message: items.isEmpty ? nil : errorMessage,
            onRetry: retry
        )
        collectionView.contentInset.bottom = paginationStatusView.isHidden ? 0 : 64
        collectionView.verticalScrollIndicatorInsets.bottom = paginationStatusView.isHidden ? 0 : 64
    }
}

extension NewsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        navigationController?.pushViewController(NewsDetailViewController(item: item), animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        Task { [viewModel] in
            await viewModel.loadNextPageIfNeeded(itemID: item.id)
        }
    }
}
