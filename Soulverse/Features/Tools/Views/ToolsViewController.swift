import Hero
import SnapKit
import UIKit

class ToolsViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let itemHeight: CGFloat = 150
        static let horizontalInset: CGFloat = 26
        static let itemHorizontalSpacing: CGFloat = 12
        static let itemVerticalSpacing: CGFloat = 16
        static let sectionHeaderHeight: CGFloat = 40
        static let mainHeaderHeight: CGFloat = 140
    }

    // MARK: - Properties

    var presenter: ToolsViewPresenterType! = ToolsViewPresenter()
    private var viewModel: ToolsViewModel = ToolsViewModel()

    private lazy var navigationView: SoulverseNavigationView = {
        let bellIcon = UIImage(systemName: "bell")
        let personIcon = UIImage(systemName: "person")

        let notificationItem = SoulverseNavigationItem.button(
            image: bellIcon,
            identifier: "notification"
        ) { [weak self] in
            self?.notificationTapped()
        }

        let profileItem = SoulverseNavigationItem.button(
            image: personIcon,
            identifier: "profile"
        ) { [weak self] in
            self?.profileTapped()
        }

        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("tools", comment: ""),
            showBackButton: false,
            rightItems: [notificationItem, profileItem]
        )

        let view = SoulverseNavigationView(config: config)
        return view
    }()

    private lazy var toolsHeaderView: ToolsHeaderView = {
        let view = ToolsHeaderView()
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Layout.itemVerticalSpacing
        layout.minimumInteritemSpacing = Layout.itemHorizontalSpacing
        layout.headerReferenceSize = CGSize(
            width: UIScreen.main.bounds.width, height: Layout.sectionHeaderHeight)
        layout.sectionInset = UIEdgeInsets(
            top: 0, left: Layout.horizontalInset, bottom: 20, right: Layout.horizontalInset)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self

        // Register Cells and Headers
        collectionView.register(
            ToolsCollectionViewCell.self, forCellWithReuseIdentifier: "ToolsCollectionViewCell")
        collectionView.register(
            ToolsSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "ToolsSectionHeaderView")

        return collectionView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPresenter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.hero.isEnabled = true
        tabBarController?.tabBar.isHidden = false

        // Re-enable swipe-to-go-back gesture when nav bar is hidden
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    // MARK: - Setup

    private func setupView() {
        view.addSubview(navigationView)
        view.addSubview(toolsHeaderView)
        view.addSubview(collectionView)

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        toolsHeaderView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(toolsHeaderView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupPresenter() {
        presenter.delegate = self
        presenter.fetchData()
    }
}

// MARK: - ToolsViewPresenterDelegate

extension ToolsViewController: ToolsViewPresenterDelegate {
    func didUpdate(viewModel: ToolsViewModel) {
        self.viewModel = viewModel
        toolsHeaderView.configure(
            title: viewModel.healingTitle,
            description: viewModel.healingDescription
        )
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension ToolsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {

        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ToolsCollectionViewCell", for: indexPath)
                as? ToolsCollectionViewCell,
            let item = viewModel.item(at: indexPath)
        else {
            return UICollectionViewCell()
        }
        cell.configure(with: item)

        // Assign Hero ID
        cell.hero.id = HeroTransitionID.toolsCell(section: indexPath.section, item: indexPath.item)

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        guard
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind, withReuseIdentifier: "ToolsSectionHeaderView", for: indexPath)
                as? ToolsSectionHeaderView
        else {
            return UICollectionReusableView()
        }
        header.configure(title: viewModel.titleForSection(indexPath.section) ?? "")
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get the selected item
        guard let item = viewModel.item(at: indexPath) else {
            print("⚠️ [Tools] Unable to get item at indexPath: \(indexPath)")
            return
        }

        // Debug log
        print("🔵 [Tools] Cell tapped at section: \(indexPath.section), item: \(indexPath.item)")
        print("🔵 [Tools] Selected: \(item.title)")

        // Check lock state before handling tool action
        if let reason = item.lockState.lockReason {
            handleLockedTool(reason: reason, title: item.title)
            return
        }

        // Notify presenter (for analytics, logging, etc.)
        presenter.didSelectTool(action: item.action)

        // Handle navigation with Hero transition
        handleToolAction(item.action, sourceIndexPath: indexPath)
    }

    private func handleLockedTool(reason: LockReason, title: String) {
        switch reason {
        case .notSubscribed:
            print("🔒 [Tools] \(title) requires subscription")
            // TODO: Present subscription prompt
        case .notImplemented:
            print("🔒 [Tools] \(title) is not yet available")
            // TODO: Show "coming soon" toast via SwiftMessages
        }
    }

    private func handleToolAction(_ action: ToolAction, sourceIndexPath: IndexPath) {
        print("🚀 [Tools] Handling action: \(action.debugDescription)")

        switch action {
        case .emotionBundle:
            // TODO: Navigate to Emotion Bundle
            print("📦 [Tools] Navigating to Emotion Bundle...")
        // AppCoordinator.openEmotionBundle(from: self)

        case .selfSoothingLabyrinth:
            print("🌀 [Tools] Navigating to Self-Soothing Labyrinth (Spiral Breathing)...")

            // Configure Hero transition for selected cell
            if let cell = collectionView.cellForItem(at: sourceIndexPath) {
                cell.hero.modifiers = [.fade, .scale(0.8)]
            }

            AppCoordinator.openSpiralBreathing(from: self)

        case .cosmicDriftBottle:
            // TODO: Navigate to Cosmic Drift Bottle
            print("💧 [Tools] Navigating to Cosmic Drift Bottle...")
        // AppCoordinator.openCosmicDriftBottle(from: self)

        case .dailyQuote:
            // TODO: Navigate to Daily Quote
            print("📖 [Tools] Navigating to Daily Quote...")
        // AppCoordinator.openDailyQuote(from: self)

        case .timeCapsule:
            // TODO: Navigate to Time Capsule
            print("⏰ [Tools] Navigating to Time Capsule...")
        // AppCoordinator.openTimeCapsule(from: self)

        case .comingSoon:
            print("⏳ [Tools] Feature coming soon...")
        // Show a toast or alert
        // SwiftMessages.show(message: "Coming Soon!")
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ToolsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = (2 * Layout.horizontalInset) + Layout.itemHorizontalSpacing
        let width = (collectionView.bounds.width - totalSpacing) / 2
        return CGSize(width: width, height: Layout.itemHeight)
    }
}


// MARK: - Navigation Actions
extension ToolsViewController {
    private func notificationTapped() {
        print("[Tools] Notification button tapped")
        // TODO: Navigate to notifications screen
    }
    
    private func profileTapped() {
        print("[Tools] Profile button tapped")
        // TODO: Navigate to profile screen
    }
}
