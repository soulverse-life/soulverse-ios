//
//  SoulverseProgressBar.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class SoulverseProgressBar: UIView {

    // MARK: - Constants

    private struct Constants {
        static let maxBarWidth: CGFloat = 24
        static let barHeight: CGFloat = 4
        static let barCornerRadius: CGFloat = 2
        static let barSpacing: CGFloat = 4
    }
    
    // MARK: - Properties

    private let totalSteps: Int
    private var currentStep: Int = 0

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private var barViews: [UIView] = []

    // MARK: - Initialization

    init(totalSteps: Int) {
        self.totalSteps = totalSteps
        super.init(frame: .zero)
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
            make.height.equalTo(Constants.barHeight)
        }

        // Create individual bar views
        for _ in 0..<totalSteps {
            let barView = createBarView()
            stackView.addArrangedSubview(barView)
            barViews.append(barView)
        }

        // Set initial state (no progress)
        updateBarColors()
    }

    private func createBarView() -> UIView {
        let view = UIView()
        view.layer.cornerRadius = Constants.barCornerRadius
        view.backgroundColor = .lightGray

        // Set max width constraint with lower priority
        // This allows the bar to shrink if needed, but prefers 24pt
        view.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(Constants.maxBarWidth).priority(.high)
            make.height.equalTo(Constants.barHeight)
        }

        return view
    }

    // MARK: - Public Methods

    /// Set the current progress step (1-indexed)
    /// - Parameter step: Current step number (1 to totalSteps)
    func setProgress(currentStep step: Int) {
        guard step >= 0 && step <= totalSteps else {
            print("[SoulverseProgressBar] Warning: Step \(step) out of range (0-\(totalSteps))")
            return
        }

        currentStep = step
        updateBarColors()
    }

    // MARK: - Private Methods

    private func updateBarColors() {
        for (index, barView) in barViews.enumerated() {
            // Only highlight the current step (1-indexed)
            let isActive = (index + 1) == currentStep

            UIView.animate(withDuration: 0.3) {
                barView.backgroundColor = isActive ? .black : .lightGray
            }
        }
    }

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        let totalWidth = CGFloat(totalSteps) * Constants.maxBarWidth + CGFloat(totalSteps - 1) * Constants.barSpacing
        return CGSize(width: totalWidth, height: Constants.barHeight)
    }
}
