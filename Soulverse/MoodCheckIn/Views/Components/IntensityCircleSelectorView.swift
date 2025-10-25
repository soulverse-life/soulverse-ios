//
//  IntensityCircleSelectorView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class IntensityCircleSelectorView: UIView {

    // MARK: - Properties

    private let circleCount = 5
    private var circleViews: [UIView] = []
    private var currentIntensity: Float = 0.5
    private var currentColor: UIColor = .yellow

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 12
        return stack
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
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Create 5 circles
        for index in 0..<circleCount {
            let circleView = createCircleView(at: index)
            stackView.addArrangedSubview(circleView)
            circleViews.append(circleView)
        }

        updateCircles()
    }

    private func createCircleView(at index: Int) -> UIView {
        let view = UIView()
        view.backgroundColor = currentColor
        view.layer.cornerRadius = 30 // Will be adjusted in constraints
        view.snp.makeConstraints { make in
            make.width.height.equalTo(60)
        }
        return view
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update corner radius to maintain circular shape
        for circleView in circleViews {
            circleView.layer.cornerRadius = circleView.bounds.width / 2
        }
    }

    // MARK: - Public Methods

    /// Update the circles based on slider position (0.0 to 1.0) and color
    func update(intensity: Float, color: UIColor) {
        self.currentIntensity = intensity
        self.currentColor = color
        updateCircles()
    }

    // MARK: - Private Methods

    private func updateCircles() {
        // Map intensity (0.0-1.0) to circle index (0-4)
        let scaledIntensity = currentIntensity * Float(circleCount - 1)
        let selectedIndex = Int(round(scaledIntensity))

        for (index, circleView) in circleViews.enumerated() {
            let isSelected = index == selectedIndex

            if isSelected {
                // Selected circle: full opacity with border
                circleView.backgroundColor = currentColor
                circleView.alpha = 1.0
                circleView.layer.borderWidth = 2
                circleView.layer.borderColor = UIColor.black.cgColor
            } else {
                // Unselected circles: reduced opacity, no border
                circleView.backgroundColor = currentColor
                circleView.alpha = 0.3
                circleView.layer.borderWidth = 0
                circleView.layer.borderColor = nil
            }
        }
    }
}
