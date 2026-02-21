//
//  SoulverseActionModal.swift
//  Soulverse
//
//  Created by Claude on 2026/2/13.
//

import UIKit
import SnapKit

// MARK: - Configuration

struct SoulverseActionModalConfig {
    let title: String
    let actionButtonTitle: String
    let contentView: UIView
}

// MARK: - Delegate

protocol SoulverseActionModalDelegate: AnyObject {
    func actionModalDidTapActionButton(_ modal: SoulverseActionModal)
    func actionModalDidDismiss(_ modal: SoulverseActionModal)
}

extension SoulverseActionModalDelegate {
    func actionModalDidDismiss(_ modal: SoulverseActionModal) {}
}

// MARK: - SoulverseActionModal

final class SoulverseActionModal: UIViewController {

    private enum Layout {
        static let horizontalPadding: CGFloat = 26
        static let topPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 24
        static let closeButtonSize: CGFloat = 44
        static let closeButtonIconSize: CGFloat = 16
        static let titleTopSpacing: CGFloat = 4
        static let contentTopSpacing: CGFloat = 16
        static let buttonTopSpacing: CGFloat = 24
        static let buttonHeight: CGFloat = ViewComponentConstants.actionButtonHeight
        static let titleFontSize: CGFloat = 18
    }

    // MARK: - Properties

    weak var delegate: SoulverseActionModalDelegate?

    private let config: SoulverseActionModalConfig

    // MARK: - UI Elements

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            button.setImage(UIImage(named: "naviconBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .center
            button.imageView?.clipsToBounds = false
            button.clipsToBounds = false
        } else {
            let image = UIImage(systemName: "xmark")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: Layout.closeButtonIconSize, weight: .medium))
            button.setImage(image, for: .normal)
            button.tintColor = .themeTextPrimary
        }
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString(
            "action_modal_close",
            comment: "Close button accessibility label"
        )
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = config.title
        return label
    }()

    private lazy var actionButton: SoulverseButton = {
        let button = SoulverseButton(title: config.actionButtonTitle, style: .primary, delegate: self)
        return button
    }()

    // MARK: - Initialization

    init(config: SoulverseActionModalConfig, delegate: SoulverseActionModalDelegate? = nil) {
        self.config = config
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureSheet()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .themeModalBackground

        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(config.contentView)
        view.addSubview(actionButton)

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.topPadding)
            make.leading.equalToSuperview().offset(Layout.horizontalPadding - (Layout.closeButtonSize - Layout.closeButtonIconSize) / 2)
            make.width.height.equalTo(Layout.closeButtonSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.top).offset(Layout.titleTopSpacing)
            make.leading.equalTo(closeButton.snp.trailing)
            make.trailing.equalToSuperview().offset(-Layout.horizontalPadding - Layout.closeButtonSize)
            make.centerX.equalToSuperview()
        }

        config.contentView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.contentTopSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
        }

        actionButton.snp.makeConstraints { make in
            make.top.equalTo(config.contentView.snp.bottom).offset(Layout.buttonTopSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
            make.height.equalTo(Layout.buttonHeight)
            make.bottom.equalToSuperview().offset(-Layout.bottomPadding)
        }
    }

    private func configureSheet() {
        guard let sheet = sheetPresentationController else { return }

        let contentDetent = UISheetPresentationController.Detent.custom(identifier: .init("content")) { [weak self] _ in
            guard let self = self else { return nil }
            // Force layout to calculate intrinsic height
            self.view.layoutIfNeeded()
            let targetSize = CGSize(width: self.view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
            return self.view.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        }

        sheet.detents = [contentDetent]
        sheet.prefersGrabberVisible = false
        sheet.preferredCornerRadius = 24
        sheet.delegate = self
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.actionModalDidDismiss(self)
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension SoulverseActionModal: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        delegate?.actionModalDidTapActionButton(self)
    }
}

// MARK: - UISheetPresentationControllerDelegate

extension SoulverseActionModal: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.actionModalDidDismiss(self)
    }
}

// MARK: - UIViewController Convenience

extension UIViewController {

    func presentActionModal(
        config: SoulverseActionModalConfig,
        delegate: SoulverseActionModalDelegate? = nil
    ) {
        let modal = SoulverseActionModal(config: config, delegate: delegate)
        present(modal, animated: true)
    }
}
