//
//  EmoPetChatView.swift
//  Soulverse
//

import SnapKit
import UIKit

struct EmoPetChatConfig {
    let image: UIImage?
    let message: String
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
        static let messageFontSize: CGFloat = 14
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
            make.right.equalToSuperview()
            make.centerY.equalTo(cardContainer)
        }

        cardContainer.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(petImageView.snp.left).offset(-Layout.petImageSpacing)
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.cardPadding)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    // MARK: - Public API

    func update(config: EmoPetChatConfig) {
        messageLabel.text = config.message
        petImageView.image = config.image
    }

    func show(in parent: UIView, animated: Bool) {
        parent.addSubview(self)
        snp.remakeConstraints { make in
            make.left.right.equalTo(parent.safeAreaLayoutGuide).inset(Layout.horizontalPadding)
            make.bottom.equalTo(parent.safeAreaLayoutGuide).inset(Layout.bottomInset)
        }
        parent.layoutIfNeeded()

        guard animated else { return }
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

    func dismiss(animated: Bool) {
        let cleanup = { [weak self] in
            guard let self = self else { return }
            self.removeFromSuperview()
            self.delegate?.emoPetChatViewDidDismiss(self)
        }

        guard animated else {
            cleanup()
            return
        }

        UIView.animate(
            withDuration: Layout.animationDuration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: Layout.animationOffset)
            },
            completion: { _ in cleanup() }
        )
    }

    // MARK: - Actions

    @objc private func didTap() {
        dismiss(animated: true)
    }
}
