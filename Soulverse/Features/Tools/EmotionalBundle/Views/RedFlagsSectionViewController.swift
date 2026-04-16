//
//  RedFlagsSectionViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

// MARK: - Delegate Protocol

protocol RedFlagsSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: RedFlagsSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: RedFlagsSectionViewController)
}

// MARK: - RedFlagsSectionViewController

final class RedFlagsSectionViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let scrollViewTopPadding: CGFloat = 8
        static let titleTopPadding: CGFloat = 24
        static let titleHorizontalPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let fieldSpacing: CGFloat = 20
        static let firstFieldTopPadding: CGFloat = 24
        static let contentBottomPadding: CGFloat = 40
    }

    // MARK: - Properties

    private var viewModel: RedFlagsSectionViewModel
    weak var delegate: RedFlagsSectionViewControllerDelegate?

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let cancelItem = SoulverseNavigationItem.button(
            image: UIImage(systemName: "xmark"),
            identifier: "cancel"
        ) { [weak self] in
            self?.handleCancel()
        }
        let saveItem = SoulverseNavigationItem.button(
            image: UIImage(systemName: "checkmark"),
            identifier: "save"
        ) { [weak self] in
            self?.handleSave()
        }
        let config = SoulverseNavigationConfig(
            title: "",
            showBackButton: false,
            rightItems: [saveItem]
        )
        let view = SoulverseNavigationView(config: config)
        view.addRightItems([cancelItem, saveItem])
        view.delegate = self
        return view
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
        label.text = NSLocalizedString("emotional_bundle_red_flags_question", comment: "")
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var redFlag1Field: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configure(
            title: NSLocalizedString("emotional_bundle_red_flag_1_title", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_red_flag_1_placeholder", comment: ""),
            text: viewModel.redFlags[0],
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.redFlags[0] = text
        }
        return field
    }()

    private lazy var redFlag2Field: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configure(
            title: NSLocalizedString("emotional_bundle_red_flag_2_title", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_red_flag_2_placeholder", comment: ""),
            text: viewModel.redFlags[1],
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.redFlags[1] = text
        }
        return field
    }()

    // MARK: - Initialization

    init(viewModel: RedFlagsSectionViewModel) {
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
        contentView.addSubview(titleLabel)
        contentView.addSubview(redFlag1Field)
        contentView.addSubview(redFlag2Field)

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
            make.left.right.equalToSuperview().inset(Layout.titleHorizontalPadding)
        }

        redFlag1Field.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.firstFieldTopPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        redFlag2Field.snp.makeConstraints { make in
            make.top.equalTo(redFlag1Field.snp.bottom).offset(Layout.fieldSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalToSuperview().offset(-Layout.contentBottomPadding)
        }
    }

    // MARK: - Actions

    private func handleSave() {
        view.endEditing(true)

        guard viewModel.isValid else {
            redFlag1Field.showError()
            return
        }

        delegate?.didTapSave(self, data: viewModel.toSectionData())
    }

    private func handleCancel() {
        view.endEditing(true)
        delegate?.didTapCancel(self)
    }
}
