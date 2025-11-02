//
//  SoulverseTagsView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit
import AlignedCollectionViewFlowLayout

/// Configuration for SoulverseTagsView layout behavior
struct SoulverseTagsViewConfig {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let itemHeight: CGFloat

    static let `default` = SoulverseTagsViewConfig(
        horizontalSpacing: 12,
        verticalSpacing: 12,
        itemHeight: 44
    )
}

/// A reusable tag/flow layout view using UICollectionView with AlignedCollectionViewFlowLayout
/// Useful for displaying buttons, tags, or other views in a flowing layout
class SoulverseTagsView: UIView {

    // MARK: - Properties

    private let config: SoulverseTagsViewConfig
    private var items: [SoulverseTagsItemData] = []

    private lazy var collectionView: UICollectionView = {
        let layout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        layout.minimumInteritemSpacing = config.horizontalSpacing
        layout.minimumLineSpacing = config.verticalSpacing
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SoulverseButtonCell.self, forCellWithReuseIdentifier: SoulverseButtonCell.reuseIdentifier)
        return collectionView
    }()

    weak var delegate: SoulverseTagsViewDelegate?

    // MARK: - Initialization

    init(config: SoulverseTagsViewConfig = .default) {
        self.config = config
        super.init(frame: .zero)
        setupCollectionView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCollectionView() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Public Methods

    /// Set the items to display in the tags view
    /// - Parameter items: Array of item data
    func setItems(_ items: [SoulverseTagsItemData]) {
        self.items = items
        collectionView.reloadData()

        // Invalidate intrinsic content size after reload
        // Use async to ensure collection view has finished layout
        DispatchQueue.main.async { [weak self] in
            self?.invalidateIntrinsicContentSize()
        }
    }

    /// Get the currently selected item index
    /// - Returns: Index of selected item, or nil if none selected
    func getSelectedIndex() -> Int? {
        return items.firstIndex { $0.isSelected }
    }

    /// Manually select an item at index
    /// - Parameter index: Index to select
    func selectItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }

        // Immediately notify delegate without modifying internal state
        // The delegate is responsible for updating the state via setItems()
        // This prevents conflicts between internal state changes and delegate-driven updates
        delegate?.soulverseTagsView(self, didSelectItemAt: index)
    }

    /// Remove all items from the tags view
    func removeAllItems() {
        items.removeAll()
        collectionView.reloadData()
    }

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        // Force layout if needed
        collectionView.layoutIfNeeded()

        // Return the content size of the collection view
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        return CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }
}

// MARK: - UICollectionViewDataSource

extension SoulverseTagsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SoulverseButtonCell.reuseIdentifier, for: indexPath) as? SoulverseButtonCell else {
            return UICollectionViewCell()
        }

        let itemData = items[indexPath.item]
        let style: SoulverseButtonStyle = itemData.isSelected ? .primary : .outlined

        cell.configure(title: itemData.title, style: style, delegate: self)

        // Apply selection styling
        if itemData.isSelected {
            cell.button.backgroundColor = .black
            cell.button.titleColor = .white
            cell.button.layer.borderColor = UIColor.black.cgColor
        } else {
            cell.button.backgroundColor = .white
            cell.button.titleColor = .black
            cell.button.layer.borderColor = UIColor.lightGray.cgColor
        }

        cell.button.tag = indexPath.item

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SoulverseTagsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItem(at: indexPath.item)
    }
}

// MARK: - SoulverseButtonDelegate

extension SoulverseTagsView: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        selectItem(at: button.tag)
    }
}

// MARK: - Supporting Types

/// Data model for items in SoulverseTagsView
struct SoulverseTagsItemData {
    let title: String
    var isSelected: Bool
}

/// Delegate protocol for SoulverseTagsView
protocol SoulverseTagsViewDelegate: AnyObject {
    func soulverseTagsView(_ view: SoulverseTagsView, didSelectItemAt index: Int)
}

// MARK: - Convenience Extensions

extension SoulverseTagsView {

    /// Create a tags view with custom spacing
    /// - Parameters:
    ///   - horizontalSpacing: Spacing between items horizontally
    ///   - verticalSpacing: Spacing between rows
    ///   - itemHeight: Height of each item
    /// - Returns: Configured SoulverseTagsView
    static func create(
        horizontalSpacing: CGFloat = 12,
        verticalSpacing: CGFloat = 12,
        itemHeight: CGFloat = 44
    ) -> SoulverseTagsView {
        let config = SoulverseTagsViewConfig(
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            itemHeight: itemHeight
        )
        return SoulverseTagsView(config: config)
    }
}
