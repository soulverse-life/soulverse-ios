//
//  InsightViewController.swift
//

import UIKit

class InsightViewController: ViewController {

    private enum Layout {
        static let weeklyMoodScoreTopSpacing: CGFloat = 16
        static let weeklyMoodScoreHorizontalPadding: CGFloat = 20
    }

    private lazy var navigationView: SoulverseNavigationView = {
        let view = SoulverseNavigationView(title: NSLocalizedString("insight", comment: ""))
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
        stackView.spacing = Layout.weeklyMoodScoreTopSpacing
        return stackView
    }()

    private lazy var weeklyMoodScoreView: WeeklyMoodScoreView = {
        let view = WeeklyMoodScoreView()
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
        contentStackView.addArrangedSubview(weeklyMoodScoreView)

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.weeklyMoodScoreTopSpacing)
            make.left.right.equalToSuperview().inset(Layout.weeklyMoodScoreHorizontalPadding)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().inset(Layout.weeklyMoodScoreHorizontalPadding)
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
            self.showLoading = viewModel.isLoading
            if let weeklyMoodScore = viewModel.weeklyMoodScore {
                self.weeklyMoodScoreView.configure(with: weeklyMoodScore)
            }
        }
    }

    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
        }
    }
}

extension InsightViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
