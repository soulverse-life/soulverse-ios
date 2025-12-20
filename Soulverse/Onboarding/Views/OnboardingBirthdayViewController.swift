//
//  OnboardingBirthdayViewController.swift
//  Soulverse
//
//

import UIKit
import SnapKit

protocol OnboardingBirthdayViewControllerDelegate: AnyObject {
    func onboardingBirthdayViewController(_ viewController: OnboardingBirthdayViewController, didSelectBirthday date: Date)
}

class OnboardingBirthdayViewController: ViewController {

    // MARK: - UI Components

    private lazy var progressView: SoulverseProgressBar = {
        let progressBar = SoulverseProgressBar(totalSteps: 5)
        progressBar.setProgress(currentStep: 2)
        return progressBar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_birthday_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .light)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_birthday_subtitle", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_birthday_instruction", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .medium)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var monthPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .clear
        return picker
    }()

    private lazy var dayPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .clear
        return picker
    }()

    private lazy var yearPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .clear
        return picker
    }()

    private lazy var pickerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [monthPickerView, dayPickerView, yearPickerView])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        return stack
    }()

    private lazy var selectedDateView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var privacyLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_birthday_privacy_notice", comment: "")
        label.font = .projectFont(ofSize: 11, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .left
        label.numberOfLines = 3
        return label
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("onboarding_continue_button", comment: ""),
            style: .primary,
            delegate: self
        )
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingBirthdayViewControllerDelegate?

    private var months: [String] {
        return [
            NSLocalizedString("onboarding_birthday_month_january", comment: ""),
            NSLocalizedString("onboarding_birthday_month_february", comment: ""),
            NSLocalizedString("onboarding_birthday_month_march", comment: ""),
            NSLocalizedString("onboarding_birthday_month_april", comment: ""),
            NSLocalizedString("onboarding_birthday_month_may", comment: ""),
            NSLocalizedString("onboarding_birthday_month_june", comment: ""),
            NSLocalizedString("onboarding_birthday_month_july", comment: ""),
            NSLocalizedString("onboarding_birthday_month_august", comment: ""),
            NSLocalizedString("onboarding_birthday_month_september", comment: ""),
            NSLocalizedString("onboarding_birthday_month_october", comment: ""),
            NSLocalizedString("onboarding_birthday_month_november", comment: ""),
            NSLocalizedString("onboarding_birthday_month_december", comment: "")
        ]
    }

    private var selectedMonth = 6 // June (0-based index)
    private var selectedDay = 15
    private var selectedYear = 1995

    private let currentYear = Calendar.current.component(.year, from: Date())

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInitialValues()
    }

    // MARK: - Setup

    private func setupUI() {

        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(selectedDateView)
        view.addSubview(pickerStackView)
        view.addSubview(privacyLabel)
        view.addSubview(continueButton)

        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.width.equalTo(ViewComponentConstants.onboardingProgressViewWidth)
            make.centerX.equalToSuperview()
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

        pickerStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
            make.height.equalTo(140)
        }

        // Add the highlighted selection view (behind pickers)
        view.insertSubview(selectedDateView, belowSubview: pickerStackView)
        selectedDateView.snp.makeConstraints { make in
            make.left.right.equalTo(pickerStackView).inset(10)
            make.centerY.equalTo(pickerStackView)
            make.height.equalTo(44)
        }

        privacyLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(pickerStackView.snp.bottom).offset(20)
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
    }

    private func setupInitialValues() {
        monthPickerView.selectRow(selectedMonth, inComponent: 0, animated: false)
        dayPickerView.selectRow(selectedDay - 1, inComponent: 0, animated: false)
        yearPickerView.selectRow(currentYear - selectedYear, inComponent: 0, animated: false)
    }

    // MARK: - Helper Methods

    private func daysInMonth() -> Int {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth + 1

        if let date = calendar.date(from: dateComponents),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        return 31
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension OnboardingBirthdayViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case monthPickerView:
            return months.count
        case dayPickerView:
            return daysInMonth()
        case yearPickerView:
            return 100 // Show 100 years back from current year
        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel
        if let reuseLabel = view as? UILabel {
            label = reuseLabel
        } else {
            label = UILabel()
            label.textAlignment = .center
            label.font = .projectFont(ofSize: 18, weight: .regular)
        }

        let text: String
        switch pickerView {
        case monthPickerView:
            text = months[row]
        case dayPickerView:
            text = "\(row + 1)"
        case yearPickerView:
            text = "\(currentYear - row)"
        default:
            text = ""
        }

        label.text = text
        label.textColor = .themeTextPrimary

        return label
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case monthPickerView:
            selectedMonth = row
            dayPickerView.reloadAllComponents() // Reload days when month changes
            // Adjust day if it's out of range for the new month
            let maxDays = daysInMonth()
            if selectedDay > maxDays {
                selectedDay = maxDays
                dayPickerView.selectRow(selectedDay - 1, inComponent: 0, animated: true)
            }
        case dayPickerView:
            selectedDay = row + 1
        case yearPickerView:
            selectedYear = currentYear - row
            dayPickerView.reloadAllComponents() // Reload days when year changes (for leap years)
        default:
            break
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension OnboardingBirthdayViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth + 1 // Convert to 1-based
        dateComponents.day = selectedDay

        if let date = calendar.date(from: dateComponents) {
            delegate?.onboardingBirthdayViewController(self, didSelectBirthday: date)
        }
    }
}
