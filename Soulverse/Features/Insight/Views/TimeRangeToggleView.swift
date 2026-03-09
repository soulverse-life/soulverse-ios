//
//  TimeRangeToggleView.swift
//

import UIKit
import SnapKit

protocol TimeRangeToggleViewDelegate: AnyObject {
    func timeRangeToggleView(_ view: TimeRangeToggleView, didSelect range: TimeRange)
}

class TimeRangeToggleView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let buttonHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 22
        static let buttonSpacing: CGFloat = 8
        static let buttonFontSize: CGFloat = 14
    }

    // MARK: - Properties

    weak var delegate: TimeRangeToggleViewDelegate?
    private(set) var selectedRange: TimeRange = .last7Days

    // MARK: - Subviews

    private let baseView: UIView = {
        let view = UIView()
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Layout.buttonSpacing
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var last7DaysButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(TimeRange.last7Days.displayTitle, for: .normal)
        button.titleLabel?.font = UIFont.projectFont(ofSize: Layout.buttonFontSize, weight: .medium)
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(last7DaysTapped), for: .touchUpInside)
        return button
    }()

    private lazy var allTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(TimeRange.all.displayTitle, for: .normal)
        button.titleLabel?.font = UIFont.projectFont(ofSize: Layout.buttonFontSize, weight: .medium)
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(allTimeTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateButtonStyles()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        updateButtonStyles()
    }

    // MARK: - Setup

    private func setupView() {
        baseView.addSubview(stackView)
        stackView.addArrangedSubview(last7DaysButton)
        stackView.addArrangedSubview(allTimeButton)

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = Layout.cardCornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(baseView)
            addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            addSubview(baseView)
            baseView.layer.cornerRadius = Layout.cardCornerRadius
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .themeCardBackground
            baseView.clipsToBounds = true
        }

        setupConstraints()
    }

    private func setupConstraints() {
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.cardPadding)
        }

        last7DaysButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Layout.buttonHeight)
        }

        allTimeButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Layout.buttonHeight)
        }
    }

    // MARK: - Actions

    @objc private func last7DaysTapped() {
        guard selectedRange != .last7Days else { return }
        selectedRange = .last7Days
        updateButtonStyles()
        delegate?.timeRangeToggleView(self, didSelect: .last7Days)
    }

    @objc private func allTimeTapped() {
        guard selectedRange != .all else { return }
        selectedRange = .all
        updateButtonStyles()
        delegate?.timeRangeToggleView(self, didSelect: .all)
    }

    // MARK: - Styling

    private func updateButtonStyles() {
        switch selectedRange {
        case .last7Days:
            applySelectedStyle(to: last7DaysButton)
            applyUnselectedStyle(to: allTimeButton)
        case .all:
            applySelectedStyle(to: allTimeButton)
            applyUnselectedStyle(to: last7DaysButton)
        }
    }

    private func applySelectedStyle(to button: UIButton) {
        button.backgroundColor = .themePrimary
        button.setTitleColor(.themeButtonPrimaryText, for: .normal)
        button.accessibilityTraits = [.button, .selected]
    }

    private func applyUnselectedStyle(to button: UIButton) {
        button.backgroundColor = .clear
        button.setTitleColor(.themeTextSecondary, for: .normal)
        button.accessibilityTraits = .button
    }
}
