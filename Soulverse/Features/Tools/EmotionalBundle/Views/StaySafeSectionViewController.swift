//
//  StaySafeSectionViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

// MARK: - Delegate Protocol

protocol StaySafeSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: StaySafeSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: StaySafeSectionViewController)
}

// MARK: - StaySafeSectionViewController

final class StaySafeSectionViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let scrollViewTopPadding: CGFloat = 8
        static let titleTopPadding: CGFloat = 24
        static let titleHorizontalPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 28
        static let iconTopPadding: CGFloat = 24
        static let iconSize: CGFloat = 36
        static let iconToTitleSpacing: CGFloat = 12
        static let firstFieldTopPadding: CGFloat = 24
        static let contentBottomPadding: CGFloat = 40
    }

    // MARK: - Properties

    private var viewModel: StaySafeSectionViewModel
    weak var delegate: StaySafeSectionViewControllerDelegate?

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let saveItem = SoulverseNavigationItem.button(
            image: UIImage(systemName: "checkmark"),
            identifier: "save"
        ) { [weak self] in
            self?.handleSave()
        }
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("emotional_bundle_section_stay_safe", comment: ""),
            showBackButton: true,
            rightItems: [saveItem]
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var sectionIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: EmotionalBundleSection.staySafe.iconName)
        imageView.tintColor = .themeTextSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("emotional_bundle_stay_safe_question", comment: "")
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configure(
            title: NSLocalizedString("emotional_bundle_stay_safe_label", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_stay_safe_placeholder", comment: ""),
            text: viewModel.action,
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.action = text
        }
        return field
    }()

    // MARK: - Initialization

    init(viewModel: StaySafeSectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(navigationView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(sectionIconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(actionField)

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

        sectionIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.iconTopPadding)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(Layout.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(sectionIconView.snp.bottom).offset(Layout.iconToTitleSpacing)
            make.left.right.equalToSuperview().inset(Layout.titleHorizontalPadding)
        }

        actionField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.firstFieldTopPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalToSuperview().offset(-Layout.contentBottomPadding)
        }
    }

    // MARK: - Actions

    private func handleSave() {
        view.endEditing(true)
        delegate?.didTapSave(self, data: viewModel.toSectionData())
    }

    private func handleCancel() {
        view.endEditing(true)
        delegate?.didTapCancel(self)
    }

    // MARK: - SoulverseNavigationViewDelegate

    func navigationViewDidTapBack(_ soulverseNavigationView: SoulverseNavigationView) {
        handleCancel()
    }
}
