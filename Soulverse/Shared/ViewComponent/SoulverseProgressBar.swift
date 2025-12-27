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
        static let barHeight: CGFloat = 4
        static let barCornerRadius: CGFloat = 2
        static let segmentSpacing: CGFloat = 6
        static let currentStepWidth: CGFloat = 24
    }

    // MARK: - Properties

    private let totalSteps: Int
    private var currentStep: Int = 0

    // Three sections: completed, current, remaining
    private lazy var completedView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.barCornerRadius
        view.layer.masksToBounds = true
        view.backgroundColor = .themeProgressBarInactive
        return view
    }()

    private lazy var currentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.barCornerRadius
        view.layer.masksToBounds = true
        view.backgroundColor = .themeProgressBarActive
        return view
    }()

    private lazy var remainingView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.barCornerRadius
        view.layer.masksToBounds = true
        view.backgroundColor = .themeProgressBarInactive
        return view
    }()

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
        // Add all three views
        addSubview(completedView)
        addSubview(currentView)
        addSubview(remainingView)
        // Don't call updateLayout() here - bounds.width is 0
        // Wait for layoutSubviews() when we have actual dimensions
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        updateLayout()
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
        
        // Animate the changes
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    // MARK: - Private Methods

    private func updateLayout() {
        // Guard against invalid layout calculations when view hasn't been laid out yet
        guard bounds.width > 0 else {
            return
        }

        // Calculate how many steps for each section
        // currentStep always >= 1 (we always show current step)
        let completedSteps = currentStep - 1  // Steps before current
        let remainingSteps = totalSteps - currentStep  // Steps after current

        // Use bounds.width if available, otherwise constraints will be 0
        let totalWidth = bounds.width

        // Calculate number of spacings between visible sections
        var numberOfSpacings = 0
        if completedSteps > 0 { numberOfSpacings += 1 } // spacing after completed
        if remainingSteps > 0 { numberOfSpacings += 1 } // spacing after current

        // Calculate available width for completed and remaining sections
        let totalSpacing = Constants.segmentSpacing * CGFloat(numberOfSpacings)
        let availableWidth = totalWidth - Constants.currentStepWidth - totalSpacing

        // Calculate width per step for completed and remaining
        let totalOtherSteps = completedSteps + remainingSteps
        let widthPerStep = totalOtherSteps > 0 ? availableWidth / CGFloat(totalOtherSteps) : 0

        // Calculate actual widths
        let completedWidth = widthPerStep * CGFloat(completedSteps)
        let remainingWidth = widthPerStep * CGFloat(remainingSteps)

        completedView.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(completedWidth) // Will be 0 if completedSteps == 0
        }

        currentView.snp.remakeConstraints { make in
            if completedSteps > 0 {
                make.left.equalTo(completedView.snp.right).offset(Constants.segmentSpacing)
            } else {
                make.left.equalToSuperview()
            }
            make.top.bottom.equalToSuperview()
            make.width.equalTo(Constants.currentStepWidth)
        }

        remainingView.snp.remakeConstraints { make in
            if remainingSteps > 0 {
                make.left.equalTo(currentView.snp.right).offset(Constants.segmentSpacing)
            } else {
                make.left.equalTo(currentView.snp.right)
            }
            make.top.bottom.equalToSuperview()
            make.width.equalTo(remainingWidth)
        }
    }

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.barHeight)
    }
}
