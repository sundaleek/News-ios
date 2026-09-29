import UIKit

@MainActor
final class NewsCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: NewsCell.self)

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let contentStack = UIStackView()
    private var imageTask: Task<Void, Never>?
    private var representedImageURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12,
            leading: 12,
            bottom: 14,
            trailing: 12
        )

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .tertiarySystemFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.layer.cornerCurve = .continuous
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 3
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(titleLabel)
        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9 / 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        representedImageURL = nil
        imageView.image = nil
        imageView.contentMode = .scaleAspectFit
        titleLabel.text = nil
    }

    func configure(with item: NewsItem) {
        imageTask?.cancel()
        imageTask = nil
        representedImageURL = item.imageURL
        titleLabel.text = item.title

        guard let imageURL = item.imageURL else {
            imageView.image = UIImage(systemName: "photo")
            return
        }

        if let cachedImage = ImageLoader.shared.cachedImage(for: imageURL) {
            imageView.contentMode = .scaleAspectFill
            imageView.image = cachedImage
            return
        }

        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "photo")
        imageTask = Task { [weak self] in
            guard let image = await ImageLoader.shared.image(for: imageURL),
                  !Task.isCancelled,
                  let self,
                  self.representedImageURL == imageURL else { return }

            self.imageView.contentMode = .scaleAspectFill
            UIView.transition(
                with: self.imageView,
                duration: 0.22,
                options: .transitionCrossDissolve
            ) {
                self.imageView.image = image
            }
        }
    }
}
