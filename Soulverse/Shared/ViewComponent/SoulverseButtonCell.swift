//
//  SoulverseButtonCell.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

/// A UICollectionViewCell that wraps a SoulverseButton for use in collection views
class SoulverseButtonCell: UICollectionViewCell {

    static let reuseIdentifier = "SoulverseButtonCell"

    // MARK: - Properties

    private(set) var button: SoulverseButton!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupButton() {
        button = SoulverseButton(title: "", style: .outlined)
        contentView.addSubview(button)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    /// Configure the cell with title and style
    func configure(title: String, style: SoulverseButtonStyle, delegate: SoulverseButtonDelegate?) {
        button.titleText = title
        button.applyStyle(style)
        button.delegate = delegate
    }

    // MARK: - Sizing

    /// Calculate the size needed for the button with given title and style
    static func size(for title: String, style: SoulverseButtonStyle, maxWidth: CGFloat) -> CGSize {
        // Create a temporary button to calculate size
        let tempButton = SoulverseButton(title: title, style: style)
        let size = tempButton.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        return size
    }
}
