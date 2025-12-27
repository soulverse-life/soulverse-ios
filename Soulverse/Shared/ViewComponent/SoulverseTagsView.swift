//
//  SoulverseTagsView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import AlignedCollectionViewFlowLayout
import SnapKit
import UIKit

/// Configuration for SoulverseTagsView layout behavior
struct SoulverseTagsViewConfig {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let itemHeight: CGFloat

    static let `default` = SoulverseTagsViewConfig(
        horizontalSpacing: 8,
        verticalSpacing: 16,
        itemHeight: 48
    )
}

/// Selection mode for Tags View
enum SoulverseTagsSelectionMode {
    case single
    case multi
}

/// Data model for items in SoulverseTagsView
struct SoulverseTagsItemData {
    let title: String
    var isSelected: Bool
    var isEnabled: Bool = true  // Added for completeness, default true
}

/// Delegate protocol for SoulverseTagsView
protocol SoulverseTagsViewDelegate: AnyObject {
    /// Called when the selection changes. Returns the list of currently selected items.
    func soulverseTagsView(
        _ view: SoulverseTagsView, didUpdateSelectedItems items: [SoulverseTagsItemData])
}

/// A reusable tag/flow layout view using UICollectionView
class SoulverseTagsView: UIView {

    // MARK: - Properties

    private let config: SoulverseTagsViewConfig
    private var items: [SoulverseTagsItemData] = []

    var selectionMode: SoulverseTagsSelectionMode = .single

    private lazy var collectionView: UICollectionView = {
        let layout = AlignedCollectionViewFlowLayout(
            horizontalAlignment: .left, verticalAlignment: .top)
        layout.minimumInteritemSpacing = config.horizontalSpacing
        layout.minimumLineSpacing = config.verticalSpacing
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        // Register the new Tag Cell
        collectionView.register(
            SoulverseTagCell.self, forCellWithReuseIdentifier: SoulverseTagCell.reuseIdentifier)
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
        DispatchQueue.main.async { [weak self] in
            self?.invalidateIntrinsicContentSize()
        }
    }

    /// Get the currently selected items
    func getSelectedItems() -> [SoulverseTagsItemData] {
        return items.filter { $0.isSelected }
    }

    /// Update internal selection state and notify delegate
    private func handleSelection(at index: Int) {
        guard index >= 0 && index < items.count else { return }

        var changed = false

        switch selectionMode {
        case .single:
            // Single Selection Loop
            // Deselect all others, Select the target if not already selected (or enforce selection)
            // Sticking to: Tap -> Selects this one.

            // If we want to allow re-tapping to do nothing or ensure it's selected:
            let wasSelected = items[index].isSelected

            // If already selected, do nothing? Or just ensure others are off?
            // "reverts others to unselected".

            // Optimization: Just loop and set.
            for i in 0..<items.count {
                let shouldBeSelected = (i == index)
                if items[i].isSelected != shouldBeSelected {
                    items[i].isSelected = shouldBeSelected
                    changed = true
                }
            }

        case .multi:
            // Multi Selection
            // Toggle the target
            items[index].isSelected.toggle()
            changed = true
        }

        if changed {
            // Update UI
            // We can reload data or just visible cells. Reload data is safer for state consistency.
            // Or reload specific items if we tracked them.
            // For simplicity and "others revert", reloading data is easiest often, but animation might be lost.
            // SoulverseTagCell doesn't seem to have complex animations needing preservation other than highlight.
            collectionView.reloadData()

            // Notify Delegate
            let selected = items.filter { $0.isSelected }
            delegate?.soulverseTagsView(self, didUpdateSelectedItems: selected)
        }
    }

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        collectionView.layoutIfNeeded()
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        return CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }
}

// MARK: - UICollectionViewDataSource

extension SoulverseTagsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SoulverseTagCell.reuseIdentifier, for: indexPath)
                as? SoulverseTagCell
        else {
            return UICollectionViewCell()
        }

        let itemData = items[indexPath.item]
        cell.configure(item: itemData)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SoulverseTagsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        handleSelection(at: indexPath.item)
    }
}

// MARK: - Convenience Extensions

extension SoulverseTagsView {
    static func create(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 16,
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
