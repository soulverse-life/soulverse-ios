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
        let view = SoulverseNavigationView(title: NSLocalizedString("tools", comment: ""))
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Layout.itemVerticalSpacing
        layout.minimumInteritemSpacing = Layout.itemHorizontalSpacing
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
            ToolsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "ToolsHeaderView")
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

        // Re-enable swipe-to-go-back gesture when nav bar is hidden
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    // MARK: - Setup

    private func setupView() {
        view.addSubview(navigationView)

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)  // Fix: Use safeAreaLayoutGuide for bottom
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
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension ToolsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ToolsCollectionViewCell", for: indexPath)
                as? ToolsCollectionViewCell,
            let item = viewModel.item(at: indexPath)
        else {
            return UICollectionViewCell()
        }
        cell.configure(with: item)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        if indexPath.section == 0 {
            guard
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind, withReuseIdentifier: "ToolsHeaderView", for: indexPath)
                    as? ToolsHeaderView
            else {
                return UICollectionReusableView()
            }
            let sectionTitle = viewModel.titleForSection(indexPath.section)
            header.configure(
                title: viewModel.healingTitle, subtitle: viewModel.healingSubtitle,
                sectionTitle: sectionTitle)
            return header
        } else {
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

        // Notify presenter (for analytics, logging, etc.)
        presenter.didSelectTool(action: item.action)

        // Handle navigation
        handleToolAction(item.action)
    }

    private func handleToolAction(_ action: ToolAction) {
        print("🚀 [Tools] Handling action: \(action.debugDescription)")

        switch action {
        case .emotionBundle:
            // TODO: Navigate to Emotion Bundle
            print("📦 [Tools] Navigating to Emotion Bundle...")
            // AppCoordinator.openEmotionBundle(from: self)

        case .selfSoothingLabyrinth:
            print("🌀 [Tools] Navigating to Self-Soothing Labyrinth (Spiral Breathing)...")
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
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = (2 * Layout.horizontalInset) + Layout.itemHorizontalSpacing
        let width = (collectionView.bounds.width - totalSpacing) / 2
        return CGSize(width: width, height: Layout.itemHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if section == 0 {
            return CGSize(width: collectionView.bounds.width, height: Layout.mainHeaderHeight)  // Adjust height as needed
        } else {
            return CGSize(width: collectionView.bounds.width, height: Layout.sectionHeaderHeight)
        }
    }
}
