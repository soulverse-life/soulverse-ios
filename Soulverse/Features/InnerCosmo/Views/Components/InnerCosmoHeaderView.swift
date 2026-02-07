//
//  InnerCosmoHeaderView.swift
//  Soulverse
//

import SnapKit
import UIKit

protocol InnerCosmoHeaderViewDelegate: AnyObject {
    func headerView(_ headerView: InnerCosmoHeaderView, didSelectPeriod period: InnerCosmoPeriod)
}

/// Header view containing greeting and period segment control for InnerCosmo
class InnerCosmoHeaderView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let greetingFontSize: CGFloat = 24
        static let greetingTopPadding: CGFloat = 16
        static let segmentControlHeight: CGFloat = 44
        static let segmentControlTopPadding: CGFloat = 16
        static let segmentControlHorizontalPadding: CGFloat = 40
        static let bottomPadding: CGFloat = 24
    }

    // MARK: - Properties

    weak var delegate: InnerCosmoHeaderViewDelegate?

    private var currentPeriod: InnerCosmoPeriod = .daily

    // MARK: - UI Components

    private lazy var greetingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.projectFont(ofSize: Layout.greetingFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let items = InnerCosmoPeriod.allCases.map { $0.title }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0

        // Custom styling for pill appearance
        control.backgroundColor = .clear
        control.selectedSegmentTintColor = .white

        // Text attributes
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: ThemeManager.shared.currentTheme.neutralLight,
            .font: UIFont.projectFont(ofSize: 15, weight: .medium)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: ThemeManager.shared.currentTheme.neutralDark,
            .font: UIFont.projectFont(ofSize: 15, weight: .semibold)
        ]

        control.setTitleTextAttributes(normalAttributes, for: .normal)
        control.setTitleTextAttributes(selectedAttributes, for: .selected)

        control.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        return control
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
        backgroundColor = .clear

        addSubview(greetingLabel)
        addSubview(segmentedControl)

        greetingLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.greetingTopPadding)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
        }

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(greetingLabel.snp.bottom).offset(Layout.segmentControlTopPadding)
            make.left.right.equalToSuperview().inset(Layout.segmentControlHorizontalPadding)
            make.height.equalTo(Layout.segmentControlHeight)
            make.bottom.equalToSuperview().offset(-Layout.bottomPadding)
        }
    }

    // MARK: - Public Methods

    /// Configure the header view with user name
    /// - Parameter userName: The user's name to display in greeting
    func configure(userName: String?) {
        let name = userName ?? NSLocalizedString("guest", comment: "")
        let greetingFormat = NSLocalizedString("inner_cosmo_greeting_format", comment: "")
        greetingLabel.text = "\u{2600}\u{FE0F} " + String(format: greetingFormat, name)
    }

    /// Set the selected period
    /// - Parameter period: The period to select
    func setSelectedPeriod(_ period: InnerCosmoPeriod) {
        currentPeriod = period
        segmentedControl.selectedSegmentIndex = period.rawValue
    }

    /// Get the currently selected period
    func getSelectedPeriod() -> InnerCosmoPeriod {
        return currentPeriod
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        guard let period = InnerCosmoPeriod(rawValue: sender.selectedSegmentIndex) else { return }
        currentPeriod = period
        delegate?.headerView(self, didSelectPeriod: period)
    }
}
