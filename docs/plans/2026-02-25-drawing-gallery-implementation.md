# Drawing Gallery Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a gallery page that displays all user drawings grouped by day in a 2-column grid, accessible from the Canvas tab's gallery button.

**Architecture:** VIPER pattern with a dedicated `DrawingGalleryPresenter` that fetches drawings via `FirestoreDrawingService`, groups them by calendar day, and feeds sections to the view. A reusable `LoadingView` shared component wraps the spinner for easy future customization.

**Tech Stack:** Swift, UIKit, SnapKit, Kingfisher, Firebase Firestore

---

### Task 1: Create LoadingView shared component

**Files:**
- Create: `Soulverse/Shared/ViewComponent/LoadingView.swift`

**Step 1: Create the LoadingView**

```swift
//
//  LoadingView.swift
//  Soulverse
//

import UIKit
import SnapKit

/// A reusable loading indicator view.
/// Currently uses UIActivityIndicatorView internally, designed to be
/// easily swapped for a custom animation (e.g., Lottie) later.
final class LoadingView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let indicatorSize: CGFloat = 40
    }

    // MARK: - UI Components

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties

    var color: UIColor? {
        get { activityIndicator.color }
        set { activityIndicator.color = newValue }
    }

    var isAnimating: Bool {
        activityIndicator.isAnimating
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Public API

    func startAnimating() {
        isHidden = false
        activityIndicator.startAnimating()
    }

    func stopAnimating() {
        activityIndicator.stopAnimating()
        isHidden = true
    }
}
```

**Step 2: Commit**

```bash
git add Soulverse/Shared/ViewComponent/LoadingView.swift
git commit -m "feat: add reusable LoadingView shared component"
```

---

### Task 2: Create DrawingGalleryViewModel

**Files:**
- Create: `Soulverse/Features/Canvas/ViewModels/DrawingGalleryViewModel.swift`

**Step 1: Create the view model following existing ToolsViewModel pattern**

```swift
//
//  DrawingGalleryViewModel.swift
//  Soulverse
//

import Foundation

struct DrawingGallerySectionViewModel {
    let title: String
    let drawings: [DrawingModel]
}

struct DrawingGalleryViewModel {
    var isLoading: Bool
    let sections: [DrawingGallerySectionViewModel]

    init(isLoading: Bool = false, sections: [DrawingGallerySectionViewModel] = []) {
        self.isLoading = isLoading
        self.sections = sections
    }

    // MARK: - Helper Methods

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfItems(in section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return sections[section].drawings.count
    }

    func drawing(at indexPath: IndexPath) -> DrawingModel? {
        guard indexPath.section < sections.count,
              indexPath.item < sections[indexPath.section].drawings.count
        else {
            return nil
        }
        return sections[indexPath.section].drawings[indexPath.item]
    }

    func titleForSection(_ section: Int) -> String? {
        guard section < sections.count else { return nil }
        return sections[section].title
    }

    var isEmpty: Bool {
        return sections.isEmpty
    }
}
```

**Step 2: Commit**

```bash
git add Soulverse/Features/Canvas/ViewModels/DrawingGalleryViewModel.swift
git commit -m "feat: add DrawingGalleryViewModel with section grouping"
```

---

### Task 3: Create DrawingGalleryPresenter

**Files:**
- Create: `Soulverse/Features/Canvas/Presenter/DrawingGalleryPresenter.swift`

**Step 1: Create the presenter that fetches and groups drawings by day**

```swift
//
//  DrawingGalleryPresenter.swift
//  Soulverse
//

import Foundation

// MARK: - Delegate Protocol

protocol DrawingGalleryPresenterDelegate: AnyObject {
    func didUpdate(viewModel: DrawingGalleryViewModel)
}

// MARK: - Presenter Protocol

protocol DrawingGalleryPresenterType: AnyObject {
    var delegate: DrawingGalleryPresenterDelegate? { get set }
    func fetchDrawings()
}

// MARK: - Implementation

final class DrawingGalleryPresenter: DrawingGalleryPresenterType {

    weak var delegate: DrawingGalleryPresenterDelegate?

    private static let fetchDaysRange: Int = 90

    private var isFetching = false

    func fetchDrawings() {
        guard !isFetching else { return }
        guard let uid = User.shared.userId else {
            delegate?.didUpdate(viewModel: DrawingGalleryViewModel())
            return
        }

        isFetching = true
        delegate?.didUpdate(viewModel: DrawingGalleryViewModel(isLoading: true))

        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -Self.fetchDaysRange,
            to: Date()
        ) ?? Date()

        FirestoreDrawingService.fetchDrawings(uid: uid, from: startDate) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetching = false

                switch result {
                case .success(let drawings):
                    let sections = self.groupByDay(drawings)
                    self.delegate?.didUpdate(
                        viewModel: DrawingGalleryViewModel(isLoading: false, sections: sections)
                    )
                case .failure:
                    self.delegate?.didUpdate(
                        viewModel: DrawingGalleryViewModel(isLoading: false)
                    )
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func groupByDay(_ drawings: [DrawingModel]) -> [DrawingGallerySectionViewModel] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        let grouped = Dictionary(grouping: drawings) { drawing -> Date in
            guard let createdAt = drawing.createdAt else { return Date.distantPast }
            return calendar.startOfDay(for: createdAt)
        }

        return grouped.keys
            .sorted(by: >)
            .map { dayDate in
                let title = dayDate == Date.distantPast
                    ? NSLocalizedString("gallery_unknown_date", comment: "Unknown date")
                    : dateFormatter.string(from: dayDate)
                let dayDrawings = grouped[dayDate] ?? []
                return DrawingGallerySectionViewModel(title: title, drawings: dayDrawings)
            }
    }
}
```

**Step 2: Commit**

```bash
git add Soulverse/Features/Canvas/Presenter/DrawingGalleryPresenter.swift
git commit -m "feat: add DrawingGalleryPresenter with day-grouping logic"
```

---

### Task 4: Create DrawingGalleryCell

**Files:**
- Create: `Soulverse/Features/Canvas/Views/DrawingGalleryCell.swift`

**Step 1: Create the collection view cell with Kingfisher image loading**

```swift
//
//  DrawingGalleryCell.swift
//  Soulverse
//

import UIKit
import SnapKit
import Kingfisher

final class DrawingGalleryCell: UICollectionViewCell {

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 12
    }

    // MARK: - UI Components

    private let drawingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .themeCardBackground
        imageView.layer.cornerRadius = Layout.cornerRadius
        return imageView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        drawingImageView.kf.cancelDownloadTask()
        drawingImageView.image = nil
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(drawingImageView)
        drawingImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with drawing: DrawingModel) {
        guard let url = URL(string: drawing.imageURL) else { return }
        drawingImageView.kf.setImage(with: url)
    }
}
```

**Step 2: Commit**

```bash
git add Soulverse/Features/Canvas/Views/DrawingGalleryCell.swift
git commit -m "feat: add DrawingGalleryCell with Kingfisher image loading"
```

---

### Task 5: Create DrawingGalleryViewController

**Files:**
- Create: `Soulverse/Features/Canvas/Views/DrawingGalleryViewController.swift`

**Step 1: Create the view controller with collection view, section headers, empty state, and LoadingView**

```swift
//
//  DrawingGalleryViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

final class DrawingGalleryViewController: UIViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalInset: CGFloat = ViewComponentConstants.horizontalPadding
        static let itemHorizontalSpacing: CGFloat = 12
        static let itemVerticalSpacing: CGFloat = 12
        static let sectionHeaderHeight: CGFloat = 40
        static let cellCornerRadius: CGFloat = 12
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
        view.backgroundColor = .systemBackground
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

// MARK: - SoulverseNavigationViewDelegate

extension DrawingGalleryViewController: SoulverseNavigationViewDelegate {}

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
}
```

**Step 2: Commit**

```bash
git add Soulverse/Features/Canvas/Views/DrawingGalleryViewController.swift
git commit -m "feat: add DrawingGalleryViewController with grouped collection view"
```

---

### Task 6: Create DrawingGallerySectionHeaderView

**Files:**
- Create: `Soulverse/Features/Canvas/Views/DrawingGallerySectionHeaderView.swift`

**Step 1: Create section header view (follows ToolsSectionHeaderView pattern)**

```swift
//
//  DrawingGallerySectionHeaderView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class DrawingGallerySectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "DrawingGallerySectionHeaderView"

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    // MARK: - Configuration

    func configure(title: String) {
        titleLabel.text = title
    }
}
```

**Step 2: Add `reuseIdentifier` to `DrawingGalleryCell` as well**

In `DrawingGalleryCell.swift`, add a static property:

```swift
static let reuseIdentifier = "DrawingGalleryCell"
```

**Step 3: Commit**

```bash
git add Soulverse/Features/Canvas/Views/DrawingGallerySectionHeaderView.swift Soulverse/Features/Canvas/Views/DrawingGalleryCell.swift
git commit -m "feat: add DrawingGallerySectionHeaderView and cell reuse identifiers"
```

---

### Task 7: Wire up navigation from CanvasViewController and AppCoordinator

**Files:**
- Modify: `Soulverse/Features/Canvas/Views/CanvasViewController.swift` (line 318: `galleryTapped()`)
- Modify: `Soulverse/Shared/Manager/AppCoordinator.swift` (add new method)

**Step 1: Add `openDrawingGallery` to AppCoordinator**

Add this method after the `openDrawingCanvas` method:

```swift
static func openDrawingGallery(from sourceVC: UIViewController) {
    let galleryVC = DrawingGalleryViewController()
    galleryVC.hidesBottomBarWhenPushed = true

    guard let navigationVC = sourceVC.navigationController else {
        sourceVC.show(galleryVC, sender: nil)
        return
    }

    navigationVC.pushViewController(galleryVC, animated: true)
}
```

**Step 2: Update `galleryTapped()` in CanvasViewController**

Replace the `galleryTapped()` method (line 317-320):

```swift
private func galleryTapped() {
    AppCoordinator.openDrawingGallery(from: self)
}
```

**Step 3: Commit**

```bash
git add Soulverse/Shared/Manager/AppCoordinator.swift Soulverse/Features/Canvas/Views/CanvasViewController.swift
git commit -m "feat: wire gallery button to DrawingGalleryViewController"
```

---

### Task 8: Add localization strings

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`
- Modify: `Soulverse/zh-TW.lproj/Localizable.strings`

**Step 1: Add English strings**

Append to `en.lproj/Localizable.strings`:

```
// Drawing Gallery
"gallery" = "Gallery";
"gallery_empty" = "No drawings yet. Start creating!";
"gallery_unknown_date" = "Unknown Date";
```

**Step 2: Add Traditional Chinese strings**

Append to `zh-TW.lproj/Localizable.strings`:

```
// Drawing Gallery
"gallery" = "畫廊";
"gallery_empty" = "還沒有畫作，開始創作吧！";
"gallery_unknown_date" = "未知日期";
```

**Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings Soulverse/zh-TW.lproj/Localizable.strings
git commit -m "feat: add localization strings for drawing gallery"
```

---

### Task 9: Register new files in Xcode project and build verification

**Step 1: Add all new Swift files to the Xcode project**

Use the `xcodeproj` Ruby gem to register these new files in the Soulverse target:

- `Soulverse/Shared/ViewComponent/LoadingView.swift`
- `Soulverse/Features/Canvas/ViewModels/DrawingGalleryViewModel.swift`
- `Soulverse/Features/Canvas/Presenter/DrawingGalleryPresenter.swift`
- `Soulverse/Features/Canvas/Views/DrawingGalleryCell.swift`
- `Soulverse/Features/Canvas/Views/DrawingGalleryViewController.swift`
- `Soulverse/Features/Canvas/Views/DrawingGallerySectionHeaderView.swift`

```ruby
ruby -e '
require "xcodeproj"

project = Xcodeproj::Project.open("Soulverse.xcodeproj")
target = project.targets.find { |t| t.name == "Soulverse" }

files = {
  "Soulverse/Shared/ViewComponent" => ["LoadingView.swift"],
  "Soulverse/Features/Canvas/ViewModels" => ["DrawingGalleryViewModel.swift"],
  "Soulverse/Features/Canvas/Presenter" => ["DrawingGalleryPresenter.swift"],
  "Soulverse/Features/Canvas/Views" => [
    "DrawingGalleryCell.swift",
    "DrawingGalleryViewController.swift",
    "DrawingGallerySectionHeaderView.swift"
  ]
}

files.each do |group_path, filenames|
  group = project.main_group.find_subpath(group_path, true)
  filenames.each do |filename|
    ref = group.new_reference(filename)
    ref.set_last_known_file_type("sourcecode.swift")
    target.source_build_phase.add_file_reference(ref)
  end
end

project.save
puts "Added all files to Xcode project"
'
```

**Step 2: Build the project**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Fix any compilation errors if they exist**

**Step 4: Final commit**

```bash
git add Soulverse.xcodeproj/project.pbxproj
git commit -m "chore: register gallery files in Xcode project"
```
