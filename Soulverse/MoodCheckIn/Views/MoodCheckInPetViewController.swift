//
//  MoodCheckInPetViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class MoodCheckInPetViewController: ViewController {

    // MARK: - Properties

    weak var delegate: MoodCheckInPetViewControllerDelegate?

    // MARK: - UI Elements

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            button.setImage(UIImage(named: "naviconBack"), for: .normal)
        } else {
            button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        }
        button.tintColor = .themeTextPrimary
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_pet_title", comment: "")
        label.font = .projectFont(ofSize: 24, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var emoPetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        // Using a placeholder - you can replace with actual EmoPet image
        imageView.backgroundColor = .themeTextSecondary
        imageView.layer.cornerRadius = 100
        return imageView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_pet_subtitle", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var beginButton: SoulverseButton = {
        let button = SoulverseButton(title: NSLocalizedString("mood_checkin_pet_begin", comment: ""), style: .primary, delegate: self)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(emoPetImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(beginButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(80)
            make.left.right.equalToSuperview().inset(40)
        }

        emoPetImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(60)
            make.width.height.equalTo(200)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(emoPetImageView.snp.bottom).offset(60)
        }

        beginButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapClose(self)
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInPetViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        delegate?.didTapBegin(self)
    }
}
