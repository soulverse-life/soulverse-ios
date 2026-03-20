//
//  InnerCosmoViewController.swift
//  Soulverse
//

import SnapKit
import UIKit

class InnerCosmoViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let recentViewTopPadding: CGFloat = 8
        static let contentViewMinHeight: CGFloat = 320
        static let moodCheckInButtonTopPadding: CGFloat = 24
        static let moodCheckInButtonWidth: CGFloat = 240
    }
    
    // MARK: - Properties

    private let presenter = InnerCosmoViewPresenter()
    private var currentPeriod: InnerCosmoPeriod = .recent

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let personIcon = UIImage(systemName: "person")

        let profileItem = SoulverseNavigationItem.button(
            image: personIcon,
            identifier: "profile"
        ) { [weak self] in
            self?.profileTapped()
        }

        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("inner_cosmo", comment: ""),
            showBackButton: false,
            rightItems: [profileItem]
        )

        let view = SoulverseNavigationView(config: config)
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        // Add refresh control
        scrollView.refreshControl = UIRefreshControl()
        scrollView.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)

        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var headerView: InnerCosmoHeaderView = {
        let view = InnerCosmoHeaderView()
        view.delegate = self
        return view
    }()

    private lazy var periodContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var recentView: InnerCosmoRecentView = {
        let view = InnerCosmoRecentView()
        return view
    }()

    private lazy var allPeriodView: InnerCosmoAllPeriodView = {
        let view = InnerCosmoAllPeriodView()
        view.delegate = self
        view.isHidden = true
        return view
    }()

    private lazy var moodEntriesSection: MoodEntriesSection = {
        let view = MoodEntriesSection()
        view.delegate = self
        view.isHidden = true  // Hidden by default, shown when entries exist
        return view
    }()

    private lazy var moodCheckInButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("inner_cosmo_mood_checkin_button", comment: ""),
            style: .primary,
            delegate: self
        )
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPresenter()
        presenter.fetchData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        recentView.startAnimations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recentView.stopAnimations()
    }

    // MARK: - Setup

    private func setupView() {
        // Hide default navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(navigationView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerView)
        contentView.addSubview(periodContainerView)

        periodContainerView.addSubview(recentView)
        periodContainerView.addSubview(allPeriodView)
        contentView.addSubview(moodEntriesSection)
        contentView.addSubview(moodCheckInButton)

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

        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        periodContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(Layout.recentViewTopPadding)
            make.left.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(Layout.contentViewMinHeight)
        }

        moodCheckInButton.snp.makeConstraints { make in
            make.top.equalTo(periodContainerView.snp.bottom).offset(Layout.moodCheckInButtonTopPadding)
            make.centerX.equalToSuperview()
            make.width.equalTo(Layout.moodCheckInButtonWidth)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        moodEntriesSection.snp.makeConstraints { make in
            make.top.equalTo(moodCheckInButton.snp.bottom).offset(InnerCosmoLayout.moodEntriesSectionTopPadding)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-ViewComponentConstants.horizontalPadding)
        }

        recentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        allPeriodView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupPresenter() {
        presenter.delegate = self
    }

    private func configure(with viewModel: InnerCosmoViewModel) {
        headerView.configure(userName: viewModel.userName)
        recentView.configure(emotions: viewModel.emotions)

        // Configure mood entries section
        let hasEntries = !viewModel.moodEntries.isEmpty
        moodEntriesSection.isHidden = !hasEntries
        if hasEntries {
            moodEntriesSection.configure(with: viewModel.moodEntries)
        }
    }

    // MARK: - Period Switching

    private func switchToPeriod(_ period: InnerCosmoPeriod) {
        currentPeriod = period

        switch period {
        case .recent:
            recentView.isHidden = false
            allPeriodView.isHidden = true
            recentView.startAnimations()
            // Restore recent entries
            let hasEntries = !presenter.currentMoodEntries.isEmpty
            moodEntriesSection.isHidden = !hasEntries
            if hasEntries {
                moodEntriesSection.configure(with: presenter.currentMoodEntries)
            }
        case .all:
            recentView.isHidden = true
            allPeriodView.isHidden = false
            recentView.stopAnimations()
            // Trigger fetch for currently visible month
            if let visible = allPeriodView.currentVisibleMonth() {
                presenter.fetchMonthData(year: visible.year, month: visible.month)
            }
        }
    }

    // MARK: - Actions

    @objc private func pullToRefresh() {
        switch currentPeriod {
        case .recent:
            presenter.fetchData(isUpdate: true)
        case .all:
            presenter.invalidateMonthCache()
            if let visible = allPeriodView.currentVisibleMonth() {
                presenter.fetchMonthData(year: visible.year, month: visible.month)
            }
            scrollView.refreshControl?.endRefreshing()
        }
    }
}

// MARK: - InnerCosmoHeaderViewDelegate

extension InnerCosmoViewController: InnerCosmoHeaderViewDelegate {
    func headerView(_ headerView: InnerCosmoHeaderView, didSelectPeriod period: InnerCosmoPeriod) {
        switchToPeriod(period)
    }
}

// MARK: - InnerCosmoViewPresenterDelegate

extension InnerCosmoViewController: InnerCosmoViewPresenterDelegate {
    func didUpdate(viewModel: InnerCosmoViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if viewModel.isLoading {
                self.showLoadingView(below: self.navigationView)
            } else {
                self.hideLoadingView()
            }
            self.scrollView.refreshControl?.endRefreshing()
            self.configure(with: viewModel)
        }
    }

    func didUpdateSection(at index: IndexSet) {
        // Not used in scroll view implementation
    }

    func didAppendMoodEntries(_ entries: [MoodEntryCardCellViewModel]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.moodEntriesSection.appendEntries(entries)
        }
    }

    func didUpdateMonthCheckInCounts(year: Int, month: Int, counts: [Int: Int]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.allPeriodView.updateMonth(year: year, month: month, checkInCounts: counts)
        }
    }

    func didRequestDayDetail(checkIns: [MoodCheckInModel]) {
        // TODO: Navigate to day detail VC with data models
        // e.g. AppCoordinator.presentDayDetail(from: self, checkIns: checkIns)
        print("[InnerCosmo] Day detail requested with \(checkIns.count) check-in(s)")
    }

    func didUpdateMonthMoodEntries(_ entries: [MoodEntryCardCellViewModel]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.currentPeriod == .all else { return }
            let hasEntries = !entries.isEmpty
            self.moodEntriesSection.isHidden = !hasEntries
            if hasEntries {
                self.moodEntriesSection.configure(with: entries)
            }
        }
    }
}

// MARK: - InnerCosmoAllPeriodViewDelegate

extension InnerCosmoViewController: InnerCosmoAllPeriodViewDelegate {
    func allPeriodView(_ view: InnerCosmoAllPeriodView, didChangeToMonth year: Int, month: Int) {
        presenter.fetchMonthData(year: year, month: month)
    }

    func allPeriodView(_ view: InnerCosmoAllPeriodView, didTapDay day: Int, inMonth month: Int, year: Int) {
        presenter.didSelectDay(day: day, month: month, year: year)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension InnerCosmoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}

// MARK: - Navigation Actions

extension InnerCosmoViewController {

    private func profileTapped() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

// MARK: - SoulverseButtonDelegate

extension InnerCosmoViewController: SoulverseButtonDelegate {

    func clickSoulverseButton(_ button: SoulverseButton) {
        if button === moodCheckInButton {
            AppCoordinator.presentMoodCheckIn(from: self) { [weak self] success, _ in
                guard let self = self, success else { return }
                // Refresh data after mood check-in completion
                self.presenter.fetchData(isUpdate: true)
            }
        }
    }
}

// MARK: - MoodEntriesSectionDelegate

extension InnerCosmoViewController: MoodEntriesSectionDelegate {

    func moodEntriesSectionDidTapDraw(_ section: MoodEntriesSection, checkinId: String?) {
        AppCoordinator.openDrawingCanvas(from: self, checkinId: checkinId)
    }

    func moodEntriesSectionDidRequestMore(_ section: MoodEntriesSection) {
        presenter.loadMoreMoodEntries()
    }
}
