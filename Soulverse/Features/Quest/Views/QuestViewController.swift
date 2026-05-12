//
//  QuestViewController.swift
//

import UIKit
import SnapKit

class QuestViewController: ViewController {

    private enum Section: Int, CaseIterable {
        case progress = 0
        case eightDimensions
        case habitChecker
        case surveys
    }

    private enum Layout {
        static let progressSectionVerticalPadding: CGFloat = 16
        static let cardSidePadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let cardVerticalPadding: CGFloat = 12
        static let lockedCardHeight: CGFloat = 220
        static let zeroHeight: CGFloat = 0.01
    }

    private lazy var navigationView: SoulverseNavigationView = {
        let bellIcon = UIImage(systemName: "bell")
        let personIcon = UIImage(systemName: "person")

        let notificationItem = SoulverseNavigationItem.button(
            image: bellIcon,
            identifier: "notification"
        ) { [weak self] in self?.notificationTapped() }

        let profileItem = SoulverseNavigationItem.button(
            image: personIcon,
            identifier: "profile"
        ) { [weak self] in self?.profileTapped() }

        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("quest", comment: ""),
            showBackButton: false,
            rightItems: [notificationItem, profileItem]
        )
        return SoulverseNavigationView(config: config)
    }()

    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.backgroundView = nil
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        table.refreshControl = UIRefreshControl()
        table.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return table
    }()

    private let presenter = QuestViewPresenter()

    /// Plan 3 — Habit Checker. Lazy because it needs an authenticated uid.
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

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.addSubview(navigationView)
        view.addSubview(tableView)
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom).offset(Layout.progressSectionVerticalPadding)
            make.left.right.bottom.equalToSuperview()
        }
        self.extendedLayoutIncludesOpaqueBars = true
    }

    @objc private func pullToRefresh() {
        presenter.start()
    }
}

// MARK: - Section rendering

extension QuestViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Layout.zeroHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return Layout.zeroHeight }
        let model = presenter.loadedModel
        switch section {
        case .progress:
            return model.progressSectionVisible ? UITableView.automaticDimension : Layout.zeroHeight
        case .eightDimensions:
            return UITableView.automaticDimension
        case .habitChecker:
            return habitCheckerSection == nil ? Layout.zeroHeight : UITableView.automaticDimension
        case .surveys:
            return model.surveySectionVisible ? UITableView.automaticDimension : Layout.zeroHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        guard let section = Section(rawValue: indexPath.section) else { return cell }
        let model = presenter.loadedModel

        switch section {
        case .progress:
            renderProgressSection(into: cell, model: model)
        case .eightDimensions:
            renderEightDimensionsSection(into: cell, model: model)
        case .habitChecker:
            renderHabitCheckerSection(into: cell, model: model)
        case .surveys:
            renderSurveySection(into: cell, model: model)
        }
        return cell
    }

    private func renderProgressSection(into cell: UITableViewCell, model: QuestViewModel) {
        guard model.progressSectionVisible else { return }
        let progressView = QuestProgressSectionView()
        progressView.configure(viewModel: model)
        progressView.onCTAtap = { [weak self] in
            self?.presenter.didTapDailyCheckInCTA()
        }
        cell.contentView.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func renderHabitCheckerSection(into cell: UITableViewCell, model: QuestViewModel) {
        guard let section = habitCheckerSection else { return }
        section.update(distinctCheckInDays: model.state.distinctCheckInDays)
        cell.contentView.addSubview(section)
        section.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

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

    private func renderEightDimensionsSection(into cell: UITableViewCell, model: QuestViewModel) {
        let card = EightDimensionsCardView()
        card.configure(model: model.eightDimensions, lockedHint: model.eightDimensionsLockedHint)
        cell.contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: Layout.cardVerticalPadding,
                             left: Layout.cardSidePadding,
                             bottom: Layout.cardVerticalPadding,
                             right: Layout.cardSidePadding)
            )
        }
    }

    private func renderSurveySection(into cell: UITableViewCell, model: QuestViewModel) {
        guard case .composed = model.surveySection else { return }
        let view = SurveySectionView()
        view.configure(model: model.surveySection)
        view.onTapPendingCard = { [weak self] type in self?.presentSurvey(for: type, focus: model.state.focusDimension) }
        view.onTapRecentResult = { [weak self] result in self?.presentRecentResult(result) }
        cell.contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
        // Recent results don't carry the full computed payload through the
        // listener — show a lightweight summary alert. A future iteration can
        // re-fetch the submission and render SurveyResultViewController.
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
            if self.tableView.refreshControl?.isRefreshing == true {
                self.tableView.refreshControl?.endRefreshing()
            }
            self.tableView.reloadData()
        }
    }

    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadSections(index, with: .automatic)
        }
    }

    func didRequestPresentMoodCheckIn() {
        AppCoordinator.presentMoodCheckIn(from: self)
    }
}

// MARK: - Navigation actions

extension QuestViewController {
    private func notificationTapped() {
        print("[Quest] Notification button tapped")
    }
    private func profileTapped() {
        print("[Quest] Profile button tapped")
    }
}
