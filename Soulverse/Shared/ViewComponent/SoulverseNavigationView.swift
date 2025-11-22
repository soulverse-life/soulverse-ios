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
    static func button(title: String? = nil, image: UIImage? = nil, identifier: String? = nil, action: @escaping () -> Void) -> SoulverseNavigationItem {
        return SoulverseNavigationItem(type: .button(title: title, image: image, action: action), identifier: identifier)
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
    
    init(title: String, showBackButton: Bool = false, rightItems: [SoulverseNavigationItem] = []) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightItems = rightItems
    }
}

class SoulverseNavigationView: UIView {
    
    weak var delegate: SoulverseNavigationViewDelegate?
    
    private let centerContainer = UIView()
    private let rightContainer = UIView()
    
    private let navigationTitle: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let backButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "naviconBack")
        button.setImage(image, for: .normal)
        return button
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
        // Add containers directly to main view
        addSubview(centerContainer)
        addSubview(rightContainer)

        // Setup height constraint
        self.snp.makeConstraints { make in
            make.height.equalTo(ViewComponentConstants.navigationBarHeight)
        }

        // Setup center container with title
        centerContainer.addSubview(navigationTitle)
        navigationTitle.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Center container constraints
        centerContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(60) // Space for back button
            make.right.lessThanOrEqualTo(rightContainer.snp.left).offset(-8)
        }

        // Right container constraints
        rightContainer.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(120) // Max width for right items
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
        navigationTitle.text = config.title
        
        // Configure back button if needed
        if config.showBackButton {
            if backButton.superview == nil {
                addSubview(backButton)
                backButton.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(8)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(44)
                }
                backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
            }
            backButton.isHidden = false
        } else {
            backButton.isHidden = true
        }
        
        // Configure right items
        if !config.rightItems.isEmpty {
            addRightItems(config.rightItems)
        } else {
            rightContainer.isHidden = true
        }
    }
    
    // MARK: - Public Methods
    
    func addRightItems(_ items: [SoulverseNavigationItem]) {
        rightContainer.subviews.forEach { $0.removeFromSuperview() }
        
        if items.count == 1 {
            // Single item - align right
            let itemView = items[0].createView()
            rightContainer.addSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(8)
                make.centerY.equalToSuperview()
                make.width.lessThanOrEqualToSuperview().inset(8)
            }
        } else {
            // Multiple items - use horizontal stack aligned right
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.alignment = .center
            stackView.spacing = 8
            
            for item in items {
                let itemView = item.createView()
                stackView.addArrangedSubview(itemView)
            }
            
            rightContainer.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(8)
                make.centerY.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview().inset(8)
            }
        }
        
        rightContainer.isHidden = false
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
        // Clear existing right content
        rightContainer.subviews.forEach { $0.removeFromSuperview() }
        // Reconfigure with new config
        configureWithConfig()
    }
    
    @objc private func didTapBack() {
        delegate?.navigationViewDidTapBack(self)
    }
    
}
