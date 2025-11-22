//
//  IntensityCircleSelectorView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

protocol IntensityCircleSelectorViewDelegate: AnyObject {
    func didSelectIntensity(_ view: IntensityCircleSelectorView, intensity: Double)
}

class IntensityCircleSelectorView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let circleSize: CGFloat = 50
        static let circleRadius: CGFloat = circleSize / 2
        static let circleSpacing: CGFloat = 12
        static let borderWidth: CGFloat = 3
        static let selectedScale: CGFloat = 1.1

        // Intensity alpha range
        static let minAlpha: Double = 0.3
        static let maxAlpha: Double = 1.0
    }

    // MARK: - Properties

    weak var delegate: IntensityCircleSelectorViewDelegate?

    private let circleCount = 5
    private var circleViews: [UIView] = []
    private var selectedIntensityIndex: Int = 2 // Default to middle circle (index 2)
    private var currentColor: UIColor = .yellow

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.spacing = Layout.circleSpacing
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
        // Container view for the circle
        let containerView = UIView()
        containerView.tag = index // Store index for tap recognition
        containerView.isUserInteractionEnabled = true

        // White background circle (prevents color mixing with parent background)
        let whiteBackgroundView = UIView()
        whiteBackgroundView.backgroundColor = .white
        whiteBackgroundView.layer.cornerRadius = Layout.circleRadius
        whiteBackgroundView.clipsToBounds = true
        whiteBackgroundView.isUserInteractionEnabled = false

        // Colored circle on top
        let coloredView = UIView()
        coloredView.backgroundColor = currentColor
        coloredView.layer.cornerRadius = Layout.circleRadius
        coloredView.clipsToBounds = true
        coloredView.isUserInteractionEnabled = false

        // Add subviews
        containerView.addSubview(whiteBackgroundView)
        containerView.addSubview(coloredView)

        // Layout
        whiteBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        coloredView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Add tap gesture to container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(circleTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)

        // Make it square (width = height) so it can be circular
        containerView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.circleSize)
        }

        return containerView
    }

    // MARK: - Public Methods

    /// Update the color displayed in circles (called when slider changes)
    func updateColor(_ color: UIColor) {
        self.currentColor = color
        updateCircles()
    }

    /// Get the currently selected intensity value (0.3 to 1.0)
    func getSelectedIntensity() -> Double {
        let range = Layout.maxAlpha - Layout.minAlpha
        let intensityDifference = range / Double(circleCount - 1)
        return Layout.minAlpha + intensityDifference * Double(selectedIntensityIndex)
    }

    // MARK: - Actions

    @objc private func circleTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        let index = tappedView.tag

        // Update selected index
        selectedIntensityIndex = index
        updateCircles()

        // Notify delegate
        let intensity = getSelectedIntensity()
        delegate?.didSelectIntensity(self, intensity: intensity)
    }

    // MARK: - Private Methods

    private func updateCircles() {
        for (index, containerView) in circleViews.enumerated() {
            let isSelected = index == selectedIntensityIndex

            // Calculate opacity based on index (0 = 30%, 4 = 100%)
            // Each circle represents an intensity level: 0.3, 0.475, 0.65, 0.825, 1.0
            let intensityLevel = Double(index) / Double(circleCount - 1) // 0.0, 0.25, 0.5, 0.75, 1.0
            let range = Layout.maxAlpha - Layout.minAlpha
            let alpha = Layout.minAlpha + (intensityLevel * range) // Range: 0.3 to 1.0

            // Get the colored view (last subview)
            guard let coloredView = containerView.subviews.last else { continue }

            // Set color with calculated opacity on the colored layer
            coloredView.backgroundColor = currentColor
            coloredView.alpha = CGFloat(alpha)

            if isSelected {
                // Selected circle: add border and slightly scale up
                coloredView.layer.borderWidth = Layout.borderWidth
                coloredView.layer.borderColor = UIColor.themeTextPrimary.cgColor
                containerView.transform = CGAffineTransform(scaleX: Layout.selectedScale, y: Layout.selectedScale)
            } else {
                // Unselected circles: no border, normal scale
                coloredView.layer.borderWidth = 0
                coloredView.layer.borderColor = nil
                containerView.transform = .identity
            }
        }
    }
}
