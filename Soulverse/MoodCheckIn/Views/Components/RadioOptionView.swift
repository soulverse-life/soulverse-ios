//
//  RadioOptionView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

protocol RadioOptionViewDelegate: AnyObject {
    func didSelectOption(_ view: RadioOptionView, at index: Int)
}

class RadioOptionView: UIView {
    
    // MARK: - Layout Constants
    private enum Layout {
        static let stackSpacing: CGFloat = 24
    }

    // MARK: - Properties

    weak var delegate: RadioOptionViewDelegate?

    private var options: [String] = []
    private var selectedIndex: Int?
    private var optionViews: [RadioOptionItemView] = []

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.alignment = .fill
        stack.spacing = Layout.stackSpacing
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
    }

    // MARK: - Public Methods

    /// Set the options to display
    func setOptions(_ options: [String]) {
        self.options = options
        self.selectedIndex = nil
        rebuildOptions()
    }

    /// Get the currently selected index
    func getSelectedIndex() -> Int? {
        return selectedIndex
    }

    /// Select an option at index
    func selectOption(at index: Int) {
        guard index >= 0 && index < options.count else { return }

        selectedIndex = index
        updateSelection()
        delegate?.didSelectOption(self, at: index)
    }

    // MARK: - Private Methods

    private func rebuildOptions() {
        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionViews.removeAll()

        // Create new option views
        for (index, option) in options.enumerated() {
            let optionView = RadioOptionItemView(text: option)
            optionView.tag = index

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:)))
            optionView.addGestureRecognizer(tapGesture)

            stackView.addArrangedSubview(optionView)
            optionViews.append(optionView)
        }

        updateSelection()
    }

    @objc private func optionTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        selectOption(at: tappedView.tag)
    }

    private func updateSelection() {
        for (index, optionView) in optionViews.enumerated() {
            optionView.setSelected(index == selectedIndex)
        }
    }
}

// MARK: - Radio Option Item View

private class RadioOptionItemView: UIView {

    // MARK: - Layout Constants
    private enum Layout {
        static let radioCircleSize: CGFloat = 30
        static let radioCircleBorderWidth: CGFloat = 2
        static let innerCircleSize: CGFloat = 18
        static let textLabelFontSize: CGFloat = 17
        static let textToRadioSpacing: CGFloat = 16
    }

    private let text: String
    private var isSelected: Bool = false

    private lazy var radioCircle: UIView = {
        let view = UIView()
        view.layer.borderWidth = Layout.radioCircleBorderWidth
        view.layer.borderColor = UIColor.themeTextPrimary.cgColor
        view.layer.cornerRadius = Layout.radioCircleSize / 2
        view.backgroundColor = .clear
        return view
    }()

    private lazy var innerCircle: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.innerCircleSize / 2
        view.backgroundColor = .themePrimary
        view.alpha = 0
        return view
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.textLabelFontSize, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initialization

    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(radioCircle)
        radioCircle.addSubview(innerCircle)
        addSubview(textLabel)

        radioCircle.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.width.height.equalTo(Layout.radioCircleSize)
        }

        innerCircle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.innerCircleSize)
        }

        textLabel.snp.makeConstraints { make in
            make.left.equalTo(radioCircle.snp.right).offset(Layout.textToRadioSpacing)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        textLabel.text = text
    }

    // MARK: - Public Methods

    func setSelected(_ selected: Bool) {
        isSelected = selected

        UIView.animate(withDuration: AnimationConstant.defaultDuration) {
            self.innerCircle.alpha = selected ? 1.0 : 0.0
        }
    }
}
