import UIKit

@MainActor
final class NewsFeedStatusView: UIView {
    enum Style {
        case empty
        case inline
    }

    private let style: Style
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let stackView = UIStackView()
    private var retryAction: (() -> Void)?

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(
        isLoading: Bool,
        message: String?,
        onRetry: @escaping () -> Void
    ) {
        retryAction = onRetry
        messageLabel.text = isLoading ? "Loading news…" : message
        retryButton.isHidden = isLoading || message == nil
        isHidden = !isLoading && message == nil

        if isLoading {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }

        guard !isHidden else { return }
        alpha = 0
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
        }
    }

    private func configureView() {
        indicator.hidesWhenStopped = true
        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = style == .empty ? .center : .left

        var buttonConfiguration = UIButton.Configuration.tinted()
        buttonConfiguration.title = "Retry"
        buttonConfiguration.image = UIImage(systemName: "arrow.clockwise")
        buttonConfiguration.imagePadding = 6
        retryButton.configuration = buttonConfiguration
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.accessibilityHint = "Retry loading news"

        stackView.axis = style == .empty ? .vertical : .horizontal
        stackView.alignment = .center
        stackView.spacing = style == .empty ? 14 : 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(indicator)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(retryButton)
        addSubview(stackView)

        if style == .empty {
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
                stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
                stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
                messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
            ])
        } else {
            backgroundColor = .secondarySystemGroupedBackground
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }

    @objc private func retryTapped() {
        retryAction?()
    }
}