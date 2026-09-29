import UIKit

@MainActor
final class NewsDetailViewController: UIViewController {
    private let item: NewsItem
    private let scrollView = UIScrollView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    init(item: NewsItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Article"
        view.backgroundColor = .systemBackground
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.numberOfLines = 0
        titleLabel.text = item.title
        bodyLabel.text = item.text.isEmpty ? "No article text available." : item.text
        view.addSubview(scrollView)
        scrollView.addSubview(titleLabel)
        scrollView.addSubview(bodyLabel)
        let readable = view.readableContentGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: readable.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: readable.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            bodyLabel.leadingAnchor.constraint(equalTo: readable.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: readable.trailingAnchor),
            bodyLabel.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            bodyLabel.widthAnchor.constraint(equalTo: readable.widthAnchor)
        ])
    }
}
