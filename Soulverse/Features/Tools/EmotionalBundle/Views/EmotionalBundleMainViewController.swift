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
    func didFinish(_ viewController: EmotionalBundleMainViewController)
}

// MARK: - EmotionalBundleMainViewController

final class EmotionalBundleMainViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let gridSpacing: CGFloat = 16
        static let scrollViewTopPadding: CGFloat = 8
        static let titleTopPadding: CGFloat = 16
        static let titleFontSize: CGFloat = 22
        static let subtitleTopPadding: CGFloat = 8
        static let subtitleHorizontalPadding: CGFloat = 20
        static let subtitleFontSize: CGFloat = 14
        static let gridTopPadding: CGFloat = 20
        static let gridBottomPadding: CGFloat = 24
        static let retryButtonWidth: CGFloat = 120
        static let retryButtonHeight: CGFloat = 44
        static let errorLabelFontSize: CGFloat = 15
        static let errorSpacing: CGFloat = 16
        static let columnsPerRow: Int = 2
    }

    // MARK: - Properties

    var presenter: EmotionalBundleMainPresenterType!
    weak var delegate: EmotionalBundleMainViewControllerDelegate?

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: "",
            showBackButton: true
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("emotional_bundle_title", comment: "")
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
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

    private lazy var gridStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Layout.gridSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    private var sectionCardViews: [BundleSectionCardView] = []
    private var chatView: EmoPetChatView?
    private let petImage = UIImage(named: "basic_first_level")

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showEmoPetChat()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissEmoPetChat()
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            delegate?.didFinish(self)
        }
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(navigationView)
        view.addSubview(scrollView)
        view.addSubview(errorContainerView)

        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(gridStackView)

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

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.titleTopPadding)
            make.left.right.equalToSuperview().inset(Layout.subtitleHorizontalPadding)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.subtitleTopPadding)
            make.left.right.equalToSuperview().inset(Layout.subtitleHorizontalPadding)
        }

        gridStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.gridTopPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalToSuperview().offset(-Layout.gridBottomPadding)
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
        let sections = EmotionalBundleSection.allCases

        // Build rows of 2 cards each
        var index = 0
        while index < sections.count {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Layout.gridSpacing
            rowStack.alignment = .fill
            rowStack.distribution = .fillEqually

            // First card in the row
            let section1 = sections[index]
            let card1 = BundleSectionCardView()
            card1.configure(title: section1.displayTitle, iconName: section1.iconName, isCompleted: false)
            card1.onTap = { [weak self] in
                guard let self = self else { return }
                self.delegate?.didSelectSection(self, section: section1)
            }
            sectionCardViews.append(card1)
            rowStack.addArrangedSubview(card1)

            // Second card in the row (or spacer if odd last item)
            if index + 1 < sections.count {
                let section2 = sections[index + 1]
                let card2 = BundleSectionCardView()
                card2.configure(title: section2.displayTitle, iconName: section2.iconName, isCompleted: false)
                card2.onTap = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didSelectSection(self, section: section2)
                }
                sectionCardViews.append(card2)
                rowStack.addArrangedSubview(card2)
            } else {
                // Add an invisible spacer view to keep single card the same width
                let spacer = UIView()
                spacer.backgroundColor = .clear
                rowStack.addArrangedSubview(spacer)
            }

            gridStackView.addArrangedSubview(rowStack)
            index += Layout.columnsPerRow
        }
    }

    // MARK: - EmoPetChatView

    private func showEmoPetChat() {
        guard chatView == nil else { return }
        let message = NSLocalizedString("emotional_bundle_emo_pet_message", comment: "")
        let newChatView = EmoPetChatView.create(config: EmoPetChatConfig(
            image: petImage,
            message: message
        ))
        newChatView.delegate = self
        chatView = newChatView
        newChatView.show(in: view)
    }

    private func dismissEmoPetChat() {
        chatView?.dismiss()
        chatView = nil
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

// MARK: - EmoPetChatViewDelegate

extension EmotionalBundleMainViewController: EmoPetChatViewDelegate {
    func emoPetChatViewDidDismiss(_ view: EmoPetChatView) {
        chatView = nil
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
                    iconName: cardViewModel.iconName,
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
