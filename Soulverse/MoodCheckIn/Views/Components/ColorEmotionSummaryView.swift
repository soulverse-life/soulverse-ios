//
//  ColorEmotionSummaryView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

/// A view that displays the selected color and emotion(s) summary
/// Shows color circle and emotion label(s) with combination when applicable
class ColorEmotionSummaryView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let colorEmotionSpacing: CGFloat = 12
    }

    // MARK: - UI Elements

    private lazy var colorDisplayView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.backgroundColor = .systemYellow
        return view
    }()

    private lazy var emotionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(colorDisplayView)
        addSubview(emotionLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        colorDisplayView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.height.equalTo(ViewComponentConstants.colorDisplaySize)
        }

        emotionLabel.snp.makeConstraints { make in
            make.left.equalTo(colorDisplayView.snp.right).offset(Layout.colorEmotionSpacing)
            make.centerY.equalTo(colorDisplayView)
            make.right.equalToSuperview()
        }
    }

    // MARK: - Public Methods

    /// Configure the view with color and recorded emotion
    /// - Parameters:
    ///   - color: The selected color
    ///   - emotion: The recorded emotion (already resolved from user selection)
    func configure(color: UIColor, emotion: RecordedEmotion) {
        colorDisplayView.backgroundColor = color

        // For combined emotions, show "Joy + Anger = Pride" format
        if let (emotion1, emotion2) = emotion.sourceEmotions {
            emotionLabel.text = "\(emotion1.displayName) + \(emotion2.displayName) = \(emotion.displayName)"
        } else {
            // For intensity-based emotions, just show the name
            emotionLabel.text = emotion.displayName
        }
    }
}
