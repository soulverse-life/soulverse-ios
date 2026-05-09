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
            // Plan 3 fills this section.
            return Layout.zeroHeight
        case .surveys:
            // Plan 4 fills this section. Until then, hidden when distinctCheckInDays < 7.
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
            break  // Plan 3
        case .surveys:
            break  // Plan 4
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

    private func renderEightDimensionsSection(into cell: UITableViewCell, model: QuestViewModel) {
        let host = UIView()
        cell.contentView.addSubview(host)
        host.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: Layout.cardVerticalPadding,
                             left: Layout.cardSidePadding,
                             bottom: Layout.cardVerticalPadding,
                             right: Layout.cardSidePadding)
            )
            make.height.equalTo(Layout.lockedCardHeight)
        }

        if model.eightDimensionsLocked {
            let locked = QuestLockedCardView()
            locked.configure(
                title: NSLocalizedString("quest_eight_dim_card_title", comment: "8-Dim card title"),
                hint: model.eightDimensionsLockedHint
            )
            host.addSubview(locked)
            locked.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        // When unlocked, Plan 5 will render the radar chart here.
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
