//
//  AddCustomHabitButton.swift
//  Soulverse
//
//  Lock-aware "Add Custom Habit" button. States: locked (Day < 14),
//  available (Day >= 14, no active custom habit), hidden (active habit exists).
//

import UIKit
import SnapKit

final class AddCustomHabitButton: UIControl {
    private enum Layout {
        static let height: CGFloat = 48
        static let cornerRadius: CGFloat = 24
        static let inset: CGFloat = 16
        static let titleFontSize: CGFloat = 17
    }

    private let titleLabel = UILabel()
    private let lockIcon = UIImageView()

    var onTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ state: AddCustomHabitButtonState) {
        switch state {
        case .locked(let daysRemaining):
            isHidden = false
            isEnabled = false
            backgroundColor = .themeButtonDisabledBackground
            lockIcon.isHidden = false
            titleLabel.textColor = .themeTextSecondary
            titleLabel.text = String(
                format: NSLocalizedString("quest_habit_add_custom_locked_format", comment: ""),
                daysRemaining
            )
        case .available:
            isHidden = false
            isEnabled = true
            backgroundColor = .themeButtonPrimaryBackground
            lockIcon.isHidden = true
            titleLabel.textColor = .themeButtonPrimaryText
            titleLabel.text = NSLocalizedString("quest_habit_add_custom_available", comment: "")
        case .hidden:
            isHidden = true
        }
    }

    private func setupView() {
        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true

        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        titleLabel.textAlignment = .center

        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = .themeTextSecondary
        lockIcon.contentMode = .scaleAspectFit

        let stack = UIStackView(arrangedSubviews: [lockIcon, titleLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isUserInteractionEnabled = false  // taps fall through to control
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Layout.inset)
        }
        lockIcon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        snp.makeConstraints { make in
            make.height.equalTo(Layout.height)
        }
    }

    @objc private func handleTap() {
        guard isEnabled else { return }
        onTap?()
    }
}
