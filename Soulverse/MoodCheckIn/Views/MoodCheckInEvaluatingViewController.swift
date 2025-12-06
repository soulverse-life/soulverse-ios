//
//  MoodCheckInEvaluatingViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class MoodCheckInEvaluatingViewController: ViewController {

    // MARK: - Properties

    weak var delegate: MoodCheckInEvaluatingViewControllerDelegate?

    private var selectedEvaluation: EvaluationOption?

    // MARK: - UI Elements

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .themeTextPrimary
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .themeTextPrimary
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var progressBar: SoulverseProgressBar = {
        let bar = SoulverseProgressBar(totalSteps: 6)
        bar.setProgress(currentStep: 5)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_evaluating_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_evaluating_subtitle", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var radioOptionView: RadioOptionView = {
        let view = RadioOptionView()
        view.delegate = self
        return view
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(title: "Continue", style: .primary, delegate: self)
        button.isEnabled = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupRadioOptions()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(promptLabel)
        view.addSubview(radioOptionView)
        view.addSubview(continueButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(44)
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(40)
        }

        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(40)
        }

        radioOptionView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(40)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupRadioOptions() {
        let options = EvaluationOption.allCases.map { $0.displayName }
        radioOptionView.setOptions(options)
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.didTapClose(self)
    }
}

// MARK: - RadioOptionViewDelegate

extension MoodCheckInEvaluatingViewController: RadioOptionViewDelegate {
    func didSelectOption(_ view: RadioOptionView, at index: Int) {
        let evaluations = Array(EvaluationOption.allCases)
        selectedEvaluation = evaluations[index]
        continueButton.isEnabled = true
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInEvaluatingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let evaluation = selectedEvaluation else { return }
        delegate?.didSelectEvaluation(self, evaluation: evaluation)
    }
}
