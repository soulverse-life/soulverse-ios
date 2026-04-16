//
//  EmotionalBundleMainViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

// MARK: - Delegate Protocol

protocol EmotionalBundleMainViewControllerDelegate: AnyObject {
    func didSelectSection(_ viewController: EmotionalBundleMainViewController, section: EmotionalBundleSection)
    func didTapClose(_ viewController: EmotionalBundleMainViewController)
}

// MARK: - EmotionalBundleMainViewController

final class EmotionalBundleMainViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let stackViewSpacing: CGFloat = 12
        static let scrollViewTopPadding: CGFloat = 8
        static let subtitleTopPadding: CGFloat = 8
        static let subtitleHorizontalPadding: CGFloat = 20
        static let subtitleFontSize: CGFloat = 14
        static let stackViewTopPadding: CGFloat = 16
        static let stackViewBottomPadding: CGFloat = 24
        static let retryButtonWidth: CGFloat = 120
        static let retryButtonHeight: CGFloat = 44
        static let errorLabelFontSize: CGFloat = 15
        static let errorSpacing: CGFloat = 16
    }

    // MARK: - Properties

    var presenter: EmotionalBundleMainPresenterType!
    weak var delegate: EmotionalBundleMainViewControllerDelegate?

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("emotional_bundle_title", comment: ""),
            showBackButton: true
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("emotional_bundle_subtitle", comment: "")
        label.font = .projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Layout.stackViewSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    private var sectionCardViews: [BundleSectionCardView] = []

    // MARK: - Error State Views

    private lazy var errorContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.errorLabelFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = NSLocalizedString("emotional_bundle_load_error", comment: "")
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("emotional_bundle_retry", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: Layout.errorLabelFontSize, weight: .medium)
        button.setTitleColor(.themePrimary, for: .normal)
        button.layer.cornerRadius = Layout.retryButtonHeight / 2
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.themePrimary.cgColor
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        createSectionCards()
        presenter.fetchData()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(navigationView)
        view.addSubview(scrollView)
        view.addSubview(errorContainerView)

        scrollView.addSubview(contentView)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(stackView)

        errorContainerView.addSubview(errorLabel)
        errorContainerView.addSubview(retryButton)

        setupConstraints()
    }

    private func setupConstraints() {
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom).offset(Layout.scrollViewTopPadding)
            make.left.right.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.subtitleTopPadding)
            make.left.right.equalToSuperview().inset(Layout.subtitleHorizontalPadding)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.stackViewTopPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalToSuperview().offset(-Layout.stackViewBottomPadding)
        }

        // Error state
        errorContainerView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        errorLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-Layout.errorSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(Layout.errorSpacing)
            make.centerX.equalToSuperview()
            make.width.equalTo(Layout.retryButtonWidth)
            make.height.equalTo(Layout.retryButtonHeight)
        }
    }

    private func createSectionCards() {
        for section in EmotionalBundleSection.allCases {
            let cardView = BundleSectionCardView()
            cardView.configure(title: section.displayTitle, isCompleted: false)
            cardView.onTap = { [weak self] in
                guard let self = self else { return }
                self.delegate?.didSelectSection(self, section: section)
            }
            sectionCardViews.append(cardView)
            stackView.addArrangedSubview(cardView)
        }
    }

    // MARK: - State Management

    private func showContentState() {
        scrollView.isHidden = false
        errorContainerView.isHidden = true
    }

    private func showErrorState() {
        scrollView.isHidden = true
        errorContainerView.isHidden = false
        hideLoadingView()
    }

    // MARK: - Actions

    @objc private func retryTapped() {
        presenter.fetchData()
    }
}

// MARK: - SoulverseNavigationViewDelegate

extension EmotionalBundleMainViewController {
    func navigationViewDidTapBack(_ soulverseNavigationView: SoulverseNavigationView) {
        delegate?.didTapClose(self)
    }
}

// MARK: - EmotionalBundleMainPresenterDelegate

extension EmotionalBundleMainViewController: EmotionalBundleMainPresenterDelegate {

    func didUpdate(viewModel: EmotionalBundleMainViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if viewModel.isLoading {
                self.showContentState()
                self.showLoadingView(below: self.navigationView)
                return
            }

            self.hideLoadingView()
            self.showContentState()

            // Update section cards
            for (index, cardViewModel) in viewModel.sectionCards.enumerated() {
                guard index < self.sectionCardViews.count else { break }
                self.sectionCardViews[index].configure(
                    title: cardViewModel.title,
                    isCompleted: cardViewModel.isCompleted
                )
            }
        }
    }

    func didFailToLoad(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showErrorState()
        }
    }
}
