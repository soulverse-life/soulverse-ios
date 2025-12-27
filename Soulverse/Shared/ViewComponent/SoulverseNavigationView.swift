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
    let rightItems: [SoulverseNavigationItem]
    let rightItemIconSize: CGFloat

    init(
        title: String, showBackButton: Bool = false, rightItems: [SoulverseNavigationItem] = [],
        rightItemIconSize: CGFloat = 20
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightItems = rightItems
        self.rightItemIconSize = rightItemIconSize
    }
}

class SoulverseNavigationView: UIView {

    // MARK: - Layout Constants
    private enum Layout {
        static let edgeInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let backButtonSize: CGFloat = 44
        static let rightItemButtonWidth: CGFloat = 28
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

    private let backButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "naviconBack")
        button.setImage(image, for: .normal)
        button.isHidden = true
        button.accessibilityLabel = NSLocalizedString(
            "navigation_back_button", comment: "Back button")
        button.accessibilityIdentifier = "SoulverseNavigationView.backButton"
        return button
    }()

    // Spacer to provide 16px left padding when back button is hidden (8px edge + 8px spacer)
    private let leadingSpacer: UIView = {
        let spacer = UIView()
        spacer.isHidden = true  // Hidden by default (shown when back button is hidden)
        return spacer
    }()

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

        // Main stack view constraints - with padding on left and right
        mainStackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview().inset(Layout.edgeInset)
            make.centerY.equalToSuperview()
        }

        // Add arranged subviews to stack
        mainStackView.addArrangedSubview(backButton)
        mainStackView.addArrangedSubview(leadingSpacer)
        mainStackView.addArrangedSubview(navigationTitle)
        mainStackView.addArrangedSubview(rightItemsStackView)
        mainStackView.addArrangedSubview(trailingSpacer)

        // Set custom spacing
        mainStackView.setCustomSpacing(0, after: backButton)  // No space between back button and title
        mainStackView.setCustomSpacing(0, after: rightItemsStackView)  // No space between right items and trailing spacer

        // Set specific constraints for items
        backButton.snp.makeConstraints { make in
            make.size.equalTo(Layout.backButtonSize)
        }

        leadingSpacer.snp.makeConstraints { make in
            make.width.equalTo(Layout.itemSpacing)
        }

        rightItemsStackView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(Layout.maxRightItemsWidth)
        }

        trailingSpacer.snp.makeConstraints { make in
            make.width.equalTo(Layout.itemSpacing)  // 8px to make total 16px with edge inset
        }

        // Setup back button action
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

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
        navigationTitle.text = config.title

        backButton.isHidden = !config.showBackButton
        leadingSpacer.isHidden = config.showBackButton

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

        // Add new items to stack with fixed size
        for item in items {
            let itemView = item.createView()

            // Check if it is a button to apply specific image padding
            if let button = itemView as? UIButton {
                // Calculate padding to enforce specified icon size within 32x32 button
                // Default is 20, derived from config
                let verticalPadding = (Layout.rightItemButtonWidth - config.rightItemIconSize) / 2
                // Ensure padding is non-negative
                let safeVerticalPadding = max(0, verticalPadding)

                // Relax horizontal padding to 0 to allow wide icons (like 'photo') to expand
                button.imageEdgeInsets = UIEdgeInsets(
                    top: safeVerticalPadding, left: 0, bottom: safeVerticalPadding, right: 0)
                button.imageView?.contentMode = .scaleAspectFit
            }

            rightItemsStackView.addArrangedSubview(itemView)

            // Set fixed 32x32 size for each right item button (tap target area)
            // Icon inside will be config.rightItemIconSize (configured effectively by the padding above)
            itemView.snp.makeConstraints { make in
                make.width.height.equalTo(Layout.rightItemButtonWidth)
            }
        }

        // Toggle visibility: when right items exist, hide trailing spacer; when empty, show trailing spacer
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
