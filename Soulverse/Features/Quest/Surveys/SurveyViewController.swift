//
//  SurveyViewController.swift
//  Soulverse
//
//  Generic survey-taking view controller, parameterized by SurveyDefinition.
//  Renders questions in a single scrollable list with per-question 5-point
//  segmented selectors. Submits when all questions answered.
//

import UIKit
import SnapKit

final class SurveyViewController: UIViewController {

    private enum Layout {
        static let outerInset: CGFloat = 20
        static let questionSpacing: CGFloat = 24
        static let optionSpacing: CGFloat = 6
        static let optionHeight: CGFloat = 36
        static let submitHeight: CGFloat = 48
        static let numberFontSize: CGFloat = 13
        static let questionFontSize: CGFloat = 17
        static let optionFontSize: CGFloat = 12
        static let submitFontSize: CGFloat = 17
    }

    let definition: SurveyDefinition
    private var responses: [Int?]   // 1-based; 0 = unanswered (we use nil)

    var onSubmit: (([SurveyResponse], SurveyComputedResult) -> Void)?
    var onCancel: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let submitButton = UIButton(type: .system)

    private var optionButtonGrid: [[UIButton]] = []   // [questionIndex][optionIndex]

    init(definition: SurveyDefinition) {
        self.definition = definition
        self.responses = Array(repeating: nil, count: definition.questions.count)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themePrimary
        title = NSLocalizedString(definition.titleKey, comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )
        setupView()
    }

    private func setupView() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = Layout.questionSpacing
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
            make.width.equalToSuperview().offset(-Layout.outerInset * 2)
        }

        for (questionIdx, question) in definition.questions.enumerated() {
            contentStack.addArrangedSubview(makeQuestionBlock(index: questionIdx, question: question))
        }

        configureSubmitButton()
        contentStack.addArrangedSubview(submitButton)
    }

    private func makeQuestionBlock(index: Int, question: SurveyQuestion) -> UIView {
        let container = UIView()

        let numberLabel = UILabel()
        numberLabel.text = "\(index + 1)."
        numberLabel.font = .projectFont(ofSize: Layout.numberFontSize, weight: .regular)
        numberLabel.textColor = .themeTextSecondary

        let textLabel = UILabel()
        textLabel.text = question.text
        textLabel.font = .projectFont(ofSize: Layout.questionFontSize, weight: .regular)
        textLabel.textColor = .themeTextPrimary
        textLabel.numberOfLines = 0

        let optionStack = UIStackView()
        optionStack.axis = .horizontal
        optionStack.distribution = .fillEqually
        optionStack.spacing = Layout.optionSpacing

        var buttonsForThisQuestion: [UIButton] = []
        let optionKeys = definition.scale.optionKeys
        for (optIdx, key) in optionKeys.enumerated() {
            let button = makeOptionButton(
                title: NSLocalizedString(key, comment: ""),
                questionIndex: index,
                value: optIdx + 1
            )
            buttonsForThisQuestion.append(button)
            optionStack.addArrangedSubview(button)
        }
        optionButtonGrid.append(buttonsForThisQuestion)

        let inner = UIStackView(arrangedSubviews: [numberLabel, textLabel, optionStack])
        inner.axis = .vertical
        inner.spacing = 8
        container.addSubview(inner)
        inner.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        optionStack.snp.makeConstraints { make in
            make.height.equalTo(Layout.optionHeight)
        }
        return container
    }

    private func makeOptionButton(title: String, questionIndex: Int, value: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: Layout.optionFontSize, weight: .regular)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 2
        button.setTitleColor(.themeTextPrimary, for: .normal)
        button.backgroundColor = .themeButtonSecondaryBackground
        button.layer.cornerRadius = Layout.optionHeight / 2
        button.addAction(UIAction { [weak self] _ in
            self?.handleSelection(questionIndex: questionIndex, value: value)
        }, for: .touchUpInside)
        return button
    }

    private func handleSelection(questionIndex: Int, value: Int) {
        responses[questionIndex] = value
        let buttons = optionButtonGrid[questionIndex]
        for (i, b) in buttons.enumerated() {
            if i + 1 == value {
                b.backgroundColor = .themeButtonPrimaryBackground
                b.setTitleColor(.themeButtonPrimaryText, for: .normal)
            } else {
                b.backgroundColor = .themeButtonSecondaryBackground
                b.setTitleColor(.themeTextPrimary, for: .normal)
            }
        }
        refreshSubmitState()
    }

    private func configureSubmitButton() {
        submitButton.setTitle(NSLocalizedString("quest_survey_submit", comment: ""), for: .normal)
        submitButton.titleLabel?.font = .projectFont(ofSize: Layout.submitFontSize, weight: .semibold)
        submitButton.setTitleColor(.themeButtonPrimaryText, for: .normal)
        submitButton.setTitleColor(.themeButtonDisabledText, for: .disabled)
        submitButton.backgroundColor = .themeButtonPrimaryBackground
        submitButton.layer.cornerRadius = Layout.submitHeight / 2
        submitButton.addAction(UIAction { [weak self] _ in self?.submitTapped() }, for: .touchUpInside)
        submitButton.snp.makeConstraints { make in
            make.height.equalTo(Layout.submitHeight)
        }
        refreshSubmitState()
    }

    private func refreshSubmitState() {
        submitButton.isEnabled = responses.allSatisfy { $0 != nil }
    }

    private func submitTapped() {
        guard responses.allSatisfy({ $0 != nil }) else { return }
        let surveyResponses: [SurveyResponse] = zip(definition.questions, responses).map { (q, val) in
            SurveyResponse(questionKey: q.questionKey, questionText: q.text, value: val ?? 0)
        }
        do {
            let result = try definition.score(surveyResponses)
            onSubmit?(surveyResponses, result)
        } catch {
            print("[Quest Survey] Scoring failed: \(error)")
        }
    }

    @objc private func cancelTapped() { onCancel?() }
}
