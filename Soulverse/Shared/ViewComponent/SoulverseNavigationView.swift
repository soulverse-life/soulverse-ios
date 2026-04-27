//
//  SoulverseNavigationView.swift
//  Soulverse
//
//  Created by mingshing on 2021/9/19.
//

import UIKit

protocol SoulverseNavigationViewDelegate: AnyObject {
    func navigationViewDidTapBack(_ soulverseNavigationView: SoulverseNavigationView)
}

// MARK: - Default Implementation
extension SoulverseNavigationViewDelegate where Self: UIViewController {
    func navigationViewDidTapBack(_ soulverseNavigationView: SoulverseNavigationView) {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}

struct SoulverseNavigationItem {
    enum ItemType {
        case button(title: String?, image: UIImage?, action: () -> Void)
        case customView(UIView)
    }

    let type: ItemType
    let identifier: String?

    // Convenience initializers
    static func button(
        title: String? = nil, image: UIImage? = nil, identifier: String? = nil,
        action: @escaping () -> Void
    ) -> SoulverseNavigationItem {
        return SoulverseNavigationItem(
            type: .button(title: title, image: image, action: action), identifier: identifier)
    }

    static func customView(_ view: UIView, identifier: String? = nil) -> SoulverseNavigationItem {
        return SoulverseNavigationItem(type: .customView(view), identifier: identifier)
    }

    // Create the actual UIView for this item
    func createView() -> UIView {
        switch type {
        case .button(let title, let image, let action):
            let button = UIButton(type: .system)

            if let title = title {
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = .projectFont(ofSize: 16, weight: .medium)
                button.setTitleColor(.themeNavigationText, for: .normal)
            }

            if let image = image {
                button.setImage(image, for: .normal)
                button.tintColor = .themeNavigationText
                button.imageView?.contentMode = .center
                button.imageView?.clipsToBounds = false
                button.clipsToBounds = false
            }

            // Store action in a way that can be called later
            button.addAction(UIAction { _ in action() }, for: .touchUpInside)

            return button

        case .customView(let view):
            return view
        }
    }
}

struct SoulverseNavigationConfig {
    let title: String
    let showBackButton: Bool
    let backButtonAssetName: String
    let backButtonFallbackSymbol: String
    let rightItems: [SoulverseNavigationItem]

    init(
        title: String, showBackButton: Bool = false,
        backButtonAssetName: String = "naviconBack",
        backButtonFallbackSymbol: String = "chevron.left",
        rightItems: [SoulverseNavigationItem] = []
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.backButtonAssetName = backButtonAssetName
        self.backButtonFallbackSymbol = backButtonFallbackSymbol
        self.rightItems = rightItems
    }
}

class SoulverseNavigationView: UIView {

    // MARK: - Layout Constants
    private enum Layout {
        static let edgeInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let backButtonSize: CGFloat = 44
        static let backButtonToTitleSpacing: CGFloat = 8
        static let rightItemButtonWidth: CGFloat = 44
        static let maxRightItemsWidth: CGFloat = 120
    }

    weak var delegate: SoulverseNavigationViewDelegate?

    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = Layout.itemSpacing
        return stack
    }()

    private let rightItemsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = Layout.itemSpacing
        stack.setContentHuggingPriority(.required, for: .horizontal)
        return stack
    }()

    private let navigationTitle: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .left
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.accessibilityLabel = NSLocalizedString("navigation_back_button", comment: "Back button")
        button.accessibilityIdentifier = "SoulverseNavigationView.backButton"
        button.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        return button
    }()

    private func applyBackButtonImage() {
        if #available(iOS 26.0, *) {
            backButton.setImage(
                UIImage(named: config.backButtonAssetName)?.withRenderingMode(.alwaysOriginal),
                for: .normal
            )
            backButton.imageView?.contentMode = .center
            backButton.imageView?.clipsToBounds = false
            backButton.clipsToBounds = false
        } else {
            backButton.setImage(UIImage(systemName: config.backButtonFallbackSymbol), for: .normal)
            backButton.tintColor = .themeTextPrimary
        }
    }

    // Spacer to provide 16px right padding when right items are hidden (8px edge + 8px spacer)
    private let trailingSpacer: UIView = {
        let spacer = UIView()
        spacer.isHidden = false  // Visible by default (hidden when right items exist)
        return spacer
    }()

    private var config: SoulverseNavigationConfig

    init(config: SoulverseNavigationConfig) {
        self.config = config
        super.init(frame: .zero)
        backgroundColor = .clear
        setupView()
        configureWithConfig()
    }

    convenience init(title: String, showBackButton: Bool = false) {
        let config = SoulverseNavigationConfig(title: title, showBackButton: showBackButton)
        self.init(config: config)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        // Add main stack view
        addSubview(mainStackView)

        // Setup height constraint
        self.snp.makeConstraints { make in
            make.height.equalTo(ViewComponentConstants.navigationBarHeight)
        }

        // Main stack view constraints — 16pt edge inset on both sides.
        mainStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.edgeInset)
            make.centerY.equalToSuperview()
        }

        // Add arranged subviews to stack
        mainStackView.addArrangedSubview(backButton)
        mainStackView.addArrangedSubview(navigationTitle)
        mainStackView.addArrangedSubview(rightItemsStackView)
        mainStackView.addArrangedSubview(trailingSpacer)

        // Set custom spacing
        mainStackView.setCustomSpacing(Layout.backButtonToTitleSpacing, after: backButton)  // 8px between back button and title
        mainStackView.setCustomSpacing(0, after: rightItemsStackView)  // No space between right items and trailing spacer

        // Set specific constraints for items
        backButton.snp.makeConstraints { make in
            make.size.equalTo(Layout.backButtonSize)
        }

        rightItemsStackView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(Layout.maxRightItemsWidth)
        }

        trailingSpacer.snp.makeConstraints { make in
            make.width.equalTo(Layout.itemSpacing)  // 8px to make total 16px with edge inset
        }

        // Apply theme colors
        updateThemeColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update colors in case theme changed
        updateThemeColors()
    }

    private func updateThemeColors() {
        navigationTitle.textColor = .themeNavigationText
    }

    private func configureWithConfig() {
        applyBackButtonImage()
        backButton.isHidden = !config.showBackButton

        navigationTitle.text = config.title
        navigationTitle.textAlignment = .left

        // Configure right items
        if !config.rightItems.isEmpty {
            addRightItems(config.rightItems)
        } else {
            rightItemsStackView.isHidden = true
        }
    }

    // MARK: - Public Methods

    func addRightItems(_ items: [SoulverseNavigationItem]) {
        // Remove existing items
        rightItemsStackView.arrangedSubviews.forEach { view in
            rightItemsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for item in items {
            let itemView = item.createView()
            rightItemsStackView.addArrangedSubview(itemView)

            switch item.type {
            case .button:
                itemView.snp.makeConstraints { make in
                    make.width.height.equalTo(Layout.rightItemButtonWidth)
                }
            case .customView:
                itemView.setContentHuggingPriority(.required, for: .horizontal)
                itemView.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
        }

        rightItemsStackView.isHidden = items.isEmpty
        trailingSpacer.isHidden = !items.isEmpty
    }

    func addRightContent(_ content: UIView) {
        let item = SoulverseNavigationItem.customView(content)
        addRightItems([item])
    }

    func updateTitle(_ title: String) {
        config = SoulverseNavigationConfig(
            title: title,
            showBackButton: config.showBackButton,
            backButtonAssetName: config.backButtonAssetName,
            backButtonFallbackSymbol: config.backButtonFallbackSymbol,
            rightItems: config.rightItems
        )
        navigationTitle.text = title
    }

    func updateConfig(_ newConfig: SoulverseNavigationConfig) {
        config = newConfig
        // Reconfigure with new config (addRightItems handles cleanup)
        configureWithConfig()
    }

    @objc private func didTapBack() {
        delegate?.navigationViewDidTapBack(self)
    }

}
