//
//  InsightViewController.swift
//

import UIKit

class InsightViewController: ViewController {

    private enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 40
    }

    private lazy var navigationView: SoulverseNavigationView = {
        let view = SoulverseNavigationView(title: NSLocalizedString("insight_mood_insight", comment: ""))
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.sectionSpacing
        return stackView
    }()

    private lazy var timeRangeToggleView: TimeRangeToggleView = {
        let view = TimeRangeToggleView()
        view.delegate = self
        return view
    }()

    private lazy var insightSummaryView: InsightSummaryView = {
        let view = InsightSummaryView()
        return view
    }()

    private lazy var weeklyMoodScoreView: WeeklyMoodScoreView = {
        let view = WeeklyMoodScoreView()
        view.delegate = self
        return view
    }()

    private lazy var topicDistributionView: TopicDistributionView = {
        let view = TopicDistributionView()
        return view
    }()

    private lazy var habitActivityView: HabitActivityView = {
        let view = HabitActivityView()
        return view
    }()

    private lazy var checkinActivityView: CheckinActivityView = {
        let view = CheckinActivityView()
        return view
    }()

    private let presenter = InsightViewPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPresenter()
        presenter.fetchData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    func setupView() {
        // Hide default navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(navigationView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(timeRangeToggleView)
        contentStackView.addArrangedSubview(insightSummaryView)
        contentStackView.addArrangedSubview(weeklyMoodScoreView)
        contentStackView.addArrangedSubview(topicDistributionView)
        contentStackView.addArrangedSubview(habitActivityView)
        contentStackView.addArrangedSubview(checkinActivityView)

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.sectionSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalToSuperview().inset(Layout.bottomPadding)
            make.width.equalToSuperview().inset(Layout.horizontalPadding)
        }
    }

    func setupPresenter() {
        presenter.delegate = self
    }
}

extension InsightViewController: InsightViewPresenterDelegate {
    func didUpdate(viewModel: InsightViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if viewModel.isLoading {
                self.showLoadingView(below: self.navigationView)
            } else {
                self.hideLoadingView()
            }
            self.insightSummaryView.configure(with: NSLocalizedString("insight_summary_placeholder", comment: ""))
            if let weeklyMoodScore = viewModel.weeklyMoodScore {
                self.weeklyMoodScoreView.configure(with: weeklyMoodScore, timeRange: viewModel.timeRange)
            }
            if let topicDistribution = viewModel.topicDistribution {
                self.topicDistributionView.configure(with: topicDistribution)
            }
            if let habitActivity = viewModel.habitActivity {
                self.habitActivityView.configure(with: habitActivity)
            }
            if let checkinActivity = viewModel.checkinActivity {
                self.checkinActivityView.configure(with: checkinActivity)
            }
        }
    }

    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
        }
    }
}

// MARK: - WeeklyMoodScoreViewDelegate

extension InsightViewController: WeeklyMoodScoreViewDelegate {
    func weeklyMoodScoreView(_ view: WeeklyMoodScoreView, didSwipeToWeekContaining date: Date) {
        presenter.fetchWeeklyMoodScore(for: date)
    }
}

extension InsightViewController: TimeRangeToggleViewDelegate {
    func timeRangeToggleView(_ view: TimeRangeToggleView, didSelect range: TimeRange) {
        presenter.setTimeRange(range)
    }
}

extension InsightViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
