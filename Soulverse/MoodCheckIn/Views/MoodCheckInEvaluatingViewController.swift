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
        if #available(iOS 26.0, *) {
            button.setImage(UIImage(named: "naviconBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .center
            button.imageView?.clipsToBounds = false
            button.clipsToBounds = false
        } else {
            button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            button.tintColor = .themeTextPrimary
        }
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var progressBar: SoulverseProgressBar = {
        let bar = SoulverseProgressBar(totalSteps: MoodCheckInLayout.totalSteps)
        bar.setProgress(currentStep: 5)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_evaluating_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .semibold)
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
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(promptLabel)
        view.addSubview(radioOptionView)
        view.addSubview(continueButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(MoodCheckInLayout.navigationTopOffset)
            make.left.equalToSuperview().offset(MoodCheckInLayout.navigationLeftOffset)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
            make.width.equalTo(ViewComponentConstants.progressViewWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(MoodCheckInLayout.titleTopOffset)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        radioOptionView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-MoodCheckInLayout.bottomPadding)
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
