//
//  OnboardingGenderViewController.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import UIKit
import SnapKit

enum GenderOption: String, CaseIterable {
    case man = "Man"
    case woman = "Woman"
    case nonBinary = "Non-binary"
    case transgender = "Transgender"
    case preferNotToSay = "Prefer not to say"
}

protocol OnboardingGenderViewControllerDelegate: AnyObject {
    func didSelectGender(_ gender: GenderOption)
}

class OnboardingGenderViewController: UIViewController {

    // MARK: - UI Components

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .black
        progress.trackTintColor = .lightGray
        progress.progress = 0.6 // Step 4 of 5
        return progress
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Gender Resonance"
        label.font = .systemFont(ofSize: 32, weight: .light)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "How should the universe\nresonate with you?"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Gender identity"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()

    private lazy var genderButtonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingGenderViewControllerDelegate?
    private var selectedGender: GenderOption?
    private var genderButtons: [UIButton] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGenderButtons()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(genderButtonsStackView)
        view.addSubview(continueButton)

        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(60)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        instructionLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(40)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(40)
        }

        genderButtonsStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
    }

    private func setupGenderButtons() {
        // Create the first row with Man and Woman buttons
        let firstRowStack = UIStackView()
        firstRowStack.axis = .horizontal
        firstRowStack.spacing = 12
        firstRowStack.distribution = .fillEqually

        let manButton = createGenderButton(for: .man)
        let womanButton = createGenderButton(for: .woman)

        // Woman is initially selected (as shown in design)
        selectGenderButton(womanButton, for: .woman)

        firstRowStack.addArrangedSubview(manButton)
        firstRowStack.addArrangedSubview(womanButton)

        // Create the second row with Non-binary and Transgender buttons
        let secondRowStack = UIStackView()
        secondRowStack.axis = .horizontal
        secondRowStack.spacing = 12
        secondRowStack.distribution = .fillEqually

        let nonBinaryButton = createGenderButton(for: .nonBinary)
        let transgenderButton = createGenderButton(for: .transgender)

        secondRowStack.addArrangedSubview(nonBinaryButton)
        secondRowStack.addArrangedSubview(transgenderButton)

        // Create the third row with Prefer not to say button
        let thirdRowStack = UIStackView()
        thirdRowStack.axis = .horizontal
        thirdRowStack.spacing = 12
        thirdRowStack.distribution = .fillEqually

        let preferNotToSayButton = createGenderButton(for: .preferNotToSay)
        let spacerView = UIView() // Empty view to maintain layout

        thirdRowStack.addArrangedSubview(preferNotToSayButton)
        thirdRowStack.addArrangedSubview(spacerView)

        genderButtonsStackView.addArrangedSubview(firstRowStack)
        genderButtonsStackView.addArrangedSubview(secondRowStack)
        genderButtonsStackView.addArrangedSubview(thirdRowStack)

        // Set height constraints for the rows
        firstRowStack.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        secondRowStack.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        thirdRowStack.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        // Ensure prefer not to say button takes only half width
        preferNotToSayButton.snp.makeConstraints { make in
            make.width.equalTo(spacerView)
        }
    }

    private func createGenderButton(for gender: GenderOption) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(gender.rawValue, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 22

        button.addTarget(self, action: #selector(genderButtonTapped(_:)), for: .touchUpInside)

        // Store the gender option as a tag or associated object
        button.tag = GenderOption.allCases.firstIndex(of: gender) ?? 0

        genderButtons.append(button)
        return button
    }

    private func selectGenderButton(_ button: UIButton, for gender: GenderOption) {
        // Deselect all buttons
        genderButtons.forEach { btn in
            btn.isSelected = false
            btn.backgroundColor = .white
            btn.setTitleColor(.black, for: .normal)
            btn.layer.borderColor = UIColor.lightGray.cgColor
        }

        // Select the tapped button
        button.isSelected = true
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.borderColor = UIColor.black.cgColor

        selectedGender = gender

        // Enable continue button
        continueButton.isEnabled = true
        continueButton.alpha = 1.0
    }

    // MARK: - Actions

    @objc private func genderButtonTapped(_ sender: UIButton) {
        let gender = GenderOption.allCases[sender.tag]
        selectGenderButton(sender, for: gender)
    }

    @objc private func continueTapped() {
        guard let selectedGender = selectedGender else { return }
        delegate?.didSelectGender(selectedGender)
    }
}