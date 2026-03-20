//
//  HabitActivityView.swift
//

import UIKit
import SnapKit

class HabitActivityView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let subtitleFontSize: CGFloat = 13
        static let titleSubtitleSpacing: CGFloat = 4
        static let headerGridSpacing: CGFloat = 16
        static let gridSpacing: CGFloat = 12
        static let borderWidth: CGFloat = 1
    }

    // MARK: - Subviews

    private let baseView: UIView = {
        let view = UIView()
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var gridContainerView: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        baseView.addSubview(titleLabel)
        baseView.addSubview(subtitleLabel)
        baseView.addSubview(gridContainerView)

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
            baseView.layer.borderWidth = Layout.borderWidth
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

        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(Layout.cardPadding)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleSubtitleSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
        }

        gridContainerView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.headerGridSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: HabitActivityViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle

        if viewModel.habits.isEmpty {
            isHidden = true
            return
        }

        isHidden = false

        // Remove existing grid cards
        gridContainerView.subviews.forEach { $0.removeFromSuperview() }

        // Map habits to grid card view models
        let cardViewModels = viewModel.habits.map { $0.toGridCardViewModel() }

        // Build 2-column grid using rows of horizontal stacks
        let rows = stride(from: 0, to: cardViewModels.count, by: 2).map { startIndex in
            let endIndex = min(startIndex + 2, cardViewModels.count)
            return Array(cardViewModels[startIndex..<endIndex])
        }

        var previousRowStack: UIStackView?

        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Layout.gridSpacing
            rowStack.distribution = .fillEqually

            for cardViewModel in row {
                let card = InsightGridCardView()
                card.configure(with: cardViewModel)
                rowStack.addArrangedSubview(card)
            }

            // If odd number of items, add spacer to keep equal width
            if row.count == 1 {
                let spacer = UIView()
                rowStack.addArrangedSubview(spacer)
            }

            gridContainerView.addSubview(rowStack)

            rowStack.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                if let previous = previousRowStack {
                    make.top.equalTo(previous.snp.bottom).offset(Layout.gridSpacing)
                } else {
                    make.top.equalToSuperview()
                }
            }

            previousRowStack = rowStack
        }

        // Pin last row to bottom
        previousRowStack?.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
        }
    }
}
