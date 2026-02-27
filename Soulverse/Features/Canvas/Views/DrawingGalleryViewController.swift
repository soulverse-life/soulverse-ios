//
//  DrawingGalleryViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

final class DrawingGalleryViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalInset: CGFloat = ViewComponentConstants.horizontalPadding
        static let itemHorizontalSpacing: CGFloat = 12
        static let itemVerticalSpacing: CGFloat = 12
        static let sectionHeaderHeight: CGFloat = 40
    }

    // MARK: - Properties

    private let presenter: DrawingGalleryPresenterType
    private var viewModel = DrawingGalleryViewModel()

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("gallery", comment: ""),
            showBackButton: true
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
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

        collectionView.register(
            DrawingGalleryCell.self,
            forCellWithReuseIdentifier: DrawingGalleryCell.reuseIdentifier)
        collectionView.register(
            DrawingGallerySectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DrawingGallerySectionHeaderView.reuseIdentifier)

        return collectionView
    }()

    private lazy var loadingView: LoadingView = {
        let view = LoadingView()
        return view
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("gallery_empty", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization

    init(presenter: DrawingGalleryPresenterType = DrawingGalleryPresenter()) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        self.presenter.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        presenter.fetchDrawings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(navigationView)
        view.addSubview(collectionView)
        view.addSubview(loadingView)
        view.addSubview(emptyLabel)
    }

    private func setupConstraints() {
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalTo(collectionView)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(collectionView)
            make.left.right.equalToSuperview().inset(Layout.horizontalInset)
        }
    }

    // MARK: - State Management

    private func updateUI() {
        if viewModel.isLoading {
            loadingView.startAnimating()
            collectionView.isHidden = true
            emptyLabel.isHidden = true
        } else if viewModel.isEmpty {
            loadingView.stopAnimating()
            collectionView.isHidden = true
            emptyLabel.isHidden = false
        } else {
            loadingView.stopAnimating()
            collectionView.isHidden = false
            emptyLabel.isHidden = true
            collectionView.reloadData()
        }
    }
}

// MARK: - DrawingGalleryPresenterDelegate

extension DrawingGalleryViewController: DrawingGalleryPresenterDelegate {
    func didUpdate(viewModel: DrawingGalleryViewModel) {
        self.viewModel = viewModel
        updateUI()
    }
}

// MARK: - UICollectionViewDataSource

extension DrawingGalleryViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DrawingGalleryCell.reuseIdentifier, for: indexPath
        ) as? DrawingGalleryCell,
              let drawing = viewModel.drawing(at: indexPath)
        else {
            return UICollectionViewCell()
        }
        cell.configure(with: drawing)
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
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: DrawingGallerySectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as? DrawingGallerySectionHeaderView else {
            return UICollectionReusableView()
        }
        header.configure(title: viewModel.titleForSection(indexPath.section) ?? "")
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DrawingGalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalHorizontalInset = Layout.horizontalInset * 2
        let availableWidth = collectionView.bounds.width - totalHorizontalInset - Layout.itemHorizontalSpacing
        let itemWidth = floor(availableWidth / 2)
        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let drawing = viewModel.drawing(at: indexPath) else { return }
        let replayVC = DrawingReplayModalViewController(drawing: drawing)
        present(replayVC, animated: true)
    }
}
