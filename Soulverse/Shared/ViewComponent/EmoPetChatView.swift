//
//  EmoPetChatView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Alignment of the pet image relative to the dialog bubble.
enum EmoPetChatAlignment {
    case imageTrailing   // bubble left, pet right (default — Quest header style)
    case imageLeading    // pet left, bubble right
}

struct EmoPetChatConfig {
    let image: UIImage?
    let message: String
    /// Optional pre-built attributed message. Takes precedence over `message`
    /// when non-nil. Use this for mixed-weight text (e.g., bold spans).
    let attributedMessage: NSAttributedString?
    let alignment: EmoPetChatAlignment

    init(
        image: UIImage?,
        message: String,
        attributedMessage: NSAttributedString? = nil,
        alignment: EmoPetChatAlignment = .imageTrailing
    ) {
        self.image = image
        self.message = message
        self.attributedMessage = attributedMessage
        self.alignment = alignment
    }
}

/// Tiny Markdown-style helper. Renders `**bold**` spans within a string into
/// an `NSAttributedString` styled with the given base font and a bolded
/// counterpart. Anything outside `**` markers keeps the base font.
enum EmoPetChatMarkdown {
    static func attributed(
        from markdown: String,
        baseFont: UIFont,
        boldFont: UIFont,
        color: UIColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var remaining = Substring(markdown)
        while let range = remaining.range(of: "**") {
            let pre = remaining[..<range.lowerBound]
            result.append(NSAttributedString(
                string: String(pre),
                attributes: [.font: baseFont, .foregroundColor: color]
            ))
            let afterOpen = remaining[range.upperBound...]
            if let closeRange = afterOpen.range(of: "**") {
                let bold = afterOpen[..<closeRange.lowerBound]
                result.append(NSAttributedString(
                    string: String(bold),
                    attributes: [.font: boldFont, .foregroundColor: color]
                ))
                remaining = afterOpen[closeRange.upperBound...]
            } else {
                remaining = afterOpen
                break
            }
        }
        if !remaining.isEmpty {
            result.append(NSAttributedString(
                string: String(remaining),
                attributes: [.font: baseFont, .foregroundColor: color]
            ))
        }
        return result
    }
}

protocol EmoPetChatViewDelegate: AnyObject {
    func emoPetChatViewDidDismiss(_ view: EmoPetChatView)
}

final class EmoPetChatView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let bottomInset: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let cardPadding: CGFloat = 12
        static let petImageSize: CGFloat = 54
        static let petImageSpacing: CGFloat = 8
        static let messageFontSize: CGFloat = 13
        static let animationDuration: TimeInterval = 0.25
        static let animationOffset: CGFloat = 8
    }

    // MARK: - Public

    weak var delegate: EmoPetChatViewDelegate?

    // MARK: - UI Components

    private lazy var cardContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .themeChatBubbleBackground
        view.layer.cornerRadius = Layout.cardCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.messageFontSize, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var petImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Initialization

    static func create(config: EmoPetChatConfig) -> EmoPetChatView {
        let view = EmoPetChatView(frame: .zero)
        view.update(config: config)
        return view
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isUserInteractionEnabled = true

        addSubview(cardContainer)
        addSubview(petImageView)
        cardContainer.addSubview(messageLabel)

        petImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.petImageSize)
            make.centerY.equalTo(cardContainer)
        }
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.cardPadding)
        }

        applyAlignment(.imageTrailing)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    private func applyAlignment(_ alignment: EmoPetChatAlignment) {
        switch alignment {
        case .imageTrailing:
            petImageView.snp.remakeConstraints { make in
                make.size.equalTo(Layout.petImageSize)
                make.right.equalToSuperview()
                make.centerY.equalTo(cardContainer)
            }
            cardContainer.snp.remakeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.right.equalTo(petImageView.snp.left).offset(-Layout.petImageSpacing)
            }
        case .imageLeading:
            petImageView.snp.remakeConstraints { make in
                make.size.equalTo(Layout.petImageSize)
                make.left.equalToSuperview()
                make.centerY.equalTo(cardContainer)
            }
            cardContainer.snp.remakeConstraints { make in
                make.right.top.bottom.equalToSuperview()
                make.left.equalTo(petImageView.snp.right).offset(Layout.petImageSpacing)
            }
        }
    }

    // MARK: - Public API

    func update(config: EmoPetChatConfig) {
        if let attributed = config.attributedMessage {
            messageLabel.attributedText = attributed
        } else {
            messageLabel.text = config.message
        }
        petImageView.image = config.image
        applyAlignment(config.alignment)
    }

    func show(in parent: UIView) {
        guard superview == nil else { return }
        parent.addSubview(self)
        snp.remakeConstraints { make in
            make.left.right.equalTo(parent.safeAreaLayoutGuide).inset(Layout.horizontalPadding)
            make.bottom.equalTo(parent.safeAreaLayoutGuide).inset(Layout.bottomInset)
        }
        parent.layoutIfNeeded()

        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: Layout.animationOffset)
        UIView.animate(
            withDuration: Layout.animationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func dismiss() {
        UIView.animate(
            withDuration: Layout.animationDuration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: Layout.animationOffset)
            },
            completion: { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.emoPetChatViewDidDismiss(self)
                self.removeFromSuperview()
            }
        )
    }

    // MARK: - Actions

    @objc private func didTap() {
        dismiss()
    }
}
