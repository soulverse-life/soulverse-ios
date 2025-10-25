//
//  MoodCheckInActingViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class MoodCheckInActingViewController: ViewController {

    // MARK: - Properties

    weak var delegate: MoodCheckInActingViewControllerDelegate?

    private var moodCheckInData: MoodCheckInData?

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
        bar.setProgress(currentStep: 6)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Acting"
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Transform your emotional awareness into\ncreative expression"
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var journeyLabel: UILabel = {
        let label = UILabel()
        label.text = "Your emotional journey"
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var summaryStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 12
        return stack
    }()

    private lazy var colorRow: UIView = {
        return createSummaryRow(title: "Color", value: "Yellow", colorView: UIView())
    }()

    private lazy var emotionsRow: UIView = {
        return createSummaryRow(title: "Emotions", value: "Joy", colorView: nil)
    }()

    private lazy var expressionRow: UIView = {
        return createSummaryRow(title: "Expression", value: "I got promoted", colorView: nil)
    }()

    private lazy var writeJournalButton: SoulverseButton = {
        let button = SoulverseButton(title: "Write a journal", style: .outlined, delegate: self)
        button.tag = 1
        return button
    }()

    private lazy var makeArtButton: SoulverseButton = {
        let button = SoulverseButton(title: "Make art", style: .outlined, delegate: self)
        button.tag = 2
        return button
    }()

    private lazy var completeButton: SoulverseButton = {
        let button = SoulverseButton(title: "Complete check-in", style: .primary, delegate: self)
        button.tag = 3
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadMoodCheckInData()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(journeyLabel)
        view.addSubview(summaryStackView)
        view.addSubview(writeJournalButton)
        view.addSubview(makeArtButton)
        view.addSubview(completeButton)

        summaryStackView.addArrangedSubview(colorRow)
        summaryStackView.addArrangedSubview(emotionsRow)
        summaryStackView.addArrangedSubview(expressionRow)

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
            make.top.equalTo(progressBar.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(40)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(40)
        }

        journeyLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
            make.left.equalToSuperview().inset(40)
        }

        summaryStackView.snp.makeConstraints { make in
            make.top.equalTo(journeyLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(40)
        }

        writeJournalButton.snp.makeConstraints { make in
            make.top.equalTo(summaryStackView.snp.bottom).offset(32)
            make.left.equalToSuperview().inset(40)
            make.width.equalTo((view.frame.width - 92) / 2)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        makeArtButton.snp.makeConstraints { make in
            make.top.equalTo(writeJournalButton)
            make.right.equalToSuperview().inset(40)
            make.width.equalTo((view.frame.width - 92) / 2)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        completeButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func createSummaryRow(title: String, value: String, colorView: UIView?) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .projectFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .themeTextSecondary

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .projectFont(ofSize: 16, weight: .regular)
        valueLabel.textColor = .themeTextPrimary
        valueLabel.tag = 100 // Tag for updating later

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(100)
        }

        if let colorView = colorView {
            colorView.layer.cornerRadius = 15
            colorView.tag = 101 // Tag for updating color
            container.addSubview(colorView)

            colorView.snp.makeConstraints { make in
                make.left.equalTo(titleLabel.snp.right).offset(8)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(30)
            }

            valueLabel.snp.makeConstraints { make in
                make.left.equalTo(colorView.snp.right).offset(8)
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        } else {
            valueLabel.snp.makeConstraints { make in
                make.left.equalTo(titleLabel.snp.right).offset(8)
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        return container
    }

    private func loadMoodCheckInData() {
        guard let data = delegate?.moodCheckInActingViewControllerGetCurrentData(self) else { return }
        self.moodCheckInData = data

        // Update color row
        if let colorView = colorRow.viewWithTag(101), let color = data.selectedColor {
            colorView.backgroundColor = color
        }
        if let valueLabel = colorRow.viewWithTag(100) as? UILabel {
            valueLabel.text = data.selectedColor != nil ? "Selected" : "N/A"
        }

        // Update emotions row
        if let valueLabel = emotionsRow.viewWithTag(100) as? UILabel {
            valueLabel.text = data.emotion?.displayName ?? "N/A"
        }

        // Update expression row
        if let valueLabel = expressionRow.viewWithTag(100) as? UILabel {
            valueLabel.text = data.promptResponse ?? "N/A"
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.moodCheckInActingViewControllerDidTapBack(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.moodCheckInActingViewControllerDidTapClose(self)
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInActingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        switch button.tag {
        case 1: // Write a journal
            delegate?.moodCheckInActingViewControllerDidTapWriteJournal(self)
        case 2: // Make art
            delegate?.moodCheckInActingViewControllerDidTapMakeArt(self)
        case 3: // Complete check-in
            delegate?.moodCheckInActingViewControllerDidTapCompleteCheckIn(self)
        default:
            break
        }
    }
}
