//
//  OnboardingBirthdayViewController.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import UIKit
import SnapKit

protocol OnboardingBirthdayViewControllerDelegate: AnyObject {
    func didSelectBirthday(_ date: Date)
}

class OnboardingBirthdayViewController: UIViewController {

    // MARK: - UI Components

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .black
        progress.trackTintColor = .lightGray
        progress.progress = 0.4 // Step 3 of 5
        return progress
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Birth Star"
        label.font = .systemFont(ofSize: 32, weight: .light)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Every soul is born at a unique\nmoment in the universe."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your birthday"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()

    private lazy var monthPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()

    private lazy var dayPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()

    private lazy var yearPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
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
        label.text = "*This information is used solely for personalized\nexperiences and research analysis — it will not be\nmade public."
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .left
        label.numberOfLines = 3
        return label
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
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingBirthdayViewControllerDelegate?

    private let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

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
        view.backgroundColor = .white

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

        pickerStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
            make.height.equalTo(120)
        }

        // Add the highlighted selection view
        selectedDateView.snp.makeConstraints { make in
            make.left.right.equalTo(pickerStackView)
            make.centerY.equalTo(pickerStackView)
            make.height.equalTo(40)
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

    // MARK: - Actions

    @objc private func continueTapped() {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth + 1 // Convert to 1-based
        dateComponents.day = selectedDay

        if let date = calendar.date(from: dateComponents) {
            delegate?.didSelectBirthday(date)
        }
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

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case monthPickerView:
            return months[row]
        case dayPickerView:
            return "\(row + 1)"
        case yearPickerView:
            return "\(currentYear - row)"
        default:
            return nil
        }
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