//
//  QuestViewController.swift
//

import UIKit
import SnapKit

class QuestViewController: ViewController {

    private enum Layout {
        static let topSpacing: CGFloat = 16
        static let stackSpacing: CGFloat = 16
        static let cardSidePadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let cardVerticalPadding: CGFloat = 12
    }


    // MARK: - Navigation

    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("quest", comment: ""),
            showBackButton: false,
            rightItems: []
        )
        return SoulverseNavigationView(config: config)
    }()

    // MARK: - Scroll container

    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.backgroundColor = .clear
        v.showsVerticalScrollIndicator = false
        v.alwaysBounceVertical = true
        return v
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private lazy var contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = Layout.stackSpacing
        return s
    }()

    // MARK: - Sections

    private lazy var headerView = QuestHeaderView()
    private lazy var progressSection = QuestProgressSectionView()
    private lazy var eightDimensionsCard = EightDimensionsCardView()
    private lazy var surveySection: SurveySectionView = {
        let v = SurveySectionView()
        v.onTapPendingCard = { [weak self] type in
            guard let self = self else { return }
            self.presentSurvey(for: type, focus: self.presenter.loadedModel.state.focusDimension)
        }
        v.onTapRecentResult = { [weak self] result in self?.presentRecentResult(result) }
        return v
    }()

    private let presenter = QuestViewPresenter()

    private lazy var habitService: FirestoreHabitService? = {
        guard let uid = User.shared.userId else { return nil }
        return FirestoreHabitService(uid: uid)
    }()

    private lazy var habitCheckerSection: HabitCheckerSection? = {
        guard let service = habitService else { return nil }
        let section = HabitCheckerSection(service: service)
        section.onAddTap = { [weak self] in self?.presentCustomHabitForm() }
        section.onDeleteTap = { [weak self] habit in self?.confirmDelete(habit: habit) }
        return section
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        presenter.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.stop()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(navigationView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Arranged sections, in display order.
        contentStack.addArrangedSubview(headerView)
        contentStack.addArrangedSubview(progressSection)
        contentStack.addArrangedSubview(eightDimensionsCardWrapper())
        if let habit = habitCheckerSection {
            contentStack.addArrangedSubview(wrapped(habit, sidePadded: true))
        }
        contentStack.addArrangedSubview(surveySection)

        self.extendedLayoutIncludesOpaqueBars = true
    }

    /// 8-Dim card needs horizontal padding inside the stack.
    private func eightDimensionsCardWrapper() -> UIView {
        return wrapped(eightDimensionsCard, sidePadded: true)
    }

    /// Wrap a view in a container that side-pads it; lets us keep the
    /// arranged subview full-width (header, dots) while padding cards.
    private func wrapped(_ inner: UIView, sidePadded: Bool) -> UIView {
        let container = UIView()
        container.addSubview(inner)
        let inset: CGFloat = sidePadded ? Layout.cardSidePadding : 0
        inner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.cardVerticalPadding)
            make.bottom.equalToSuperview().inset(Layout.cardVerticalPadding)
            make.left.equalToSuperview().offset(inset)
            make.right.equalToSuperview().offset(-inset)
        }
        return container
    }

    // MARK: - Modal flows

    private func presentCustomHabitForm() {
        guard let service = habitService else { return }
        let formVC = CustomHabitFormViewController()
        formVC.onSave = { [weak self] name, unit, increments in
            service.createCustomHabit(name: name, unit: unit, increments: increments)
            self?.dismiss(animated: true)
        }
        formVC.onCancel = { [weak self] in self?.dismiss(animated: true) }
        let nav = UINavigationController(rootViewController: formVC)
        present(nav, animated: true)
    }

    private func confirmDelete(habit: CustomHabit) {
        guard let service = habitService else { return }
        let alert = CustomHabitDeletionConfirmation.make(habitName: habit.name) {
            service.softDeleteCustomHabit(id: habit.id)
        }
        present(alert, animated: true)
    }

    private func presentSurvey(for type: QuestSurveyType, focus: Topic?) {
        let definition = SurveyDefinition.definition(for: type, dimension: focus)
        let surveyVC = SurveyViewController(definition: definition)
        surveyVC.onCancel = { [weak self] in self?.dismiss(animated: true) }
        surveyVC.onSubmit = { [weak self] responses, result in
            guard let self = self, let uid = User.shared.userId else { return }
            FirestoreSurveyService.submit(
                uid: uid,
                kind: type,
                responses: responses,
                result: result,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
                submittedFromQuestDay: self.presenter.loadedModel.state.distinctCheckInDays
            ) { _ in }
            self.dismiss(animated: true) {
                let resultVC = SurveyResultViewController(result: result)
                resultVC.onDone = { [weak self] in self?.dismiss(animated: true) }
                let nav = UINavigationController(rootViewController: resultVC)
                self.present(nav, animated: true)
            }
        }
        let nav = UINavigationController(rootViewController: surveyVC)
        present(nav, animated: true)
    }

    private func presentRecentResult(_ result: RecentResultCardModel) {
        let alert = UIAlertController(
            title: NSLocalizedString(result.titleKey, comment: ""),
            message: NSLocalizedString(result.summaryKey, comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("quest_survey_result_done", comment: ""), style: .default))
        present(alert, animated: true)
    }

}

// MARK: - Presenter delegate

extension QuestViewController: QuestViewPresenterDelegate {

    func didUpdate(viewModel: QuestViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if viewModel.isLoading {
                self.showLoadingView(below: self.navigationView)
            } else {
                self.hideLoadingView()
            }
            self.applyViewModel(viewModel)
        }
    }

    func didRequestPresentMoodCheckIn() {
        AppCoordinator.presentMoodCheckIn(from: self)
    }

    private func applyViewModel(_ viewModel: QuestViewModel) {
        headerView.configure(viewModel: viewModel)
        progressSection.configure(viewModel: viewModel)
        let dimensionsModel = DevConstants.usingMockData
            ? EightDimensionsRenderModel.mockPhysicalStage2
            : viewModel.eightDimensions
        eightDimensionsCard.configure(
            model: dimensionsModel,
            lockedHint: viewModel.eightDimensionsLockedHint
        )
        habitCheckerSection?.update(distinctCheckInDays: viewModel.state.distinctCheckInDays)

        // Survey section is hidden pre-day-7 (via SurveySectionModel.hidden)
        // or whenever the composer returns .hidden. SurveySectionView.configure
        // already toggles its own isHidden flag based on the model.
        let surveyModel = DevConstants.usingMockData
            ? SurveySectionModel.mockEngagedUser
            : viewModel.surveySection
        surveySection.configure(model: surveyModel)
    }
}
