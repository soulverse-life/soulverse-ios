//
//  ProfessionalSupportSectionViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

// MARK: - Delegate Protocol

protocol ProfessionalSupportSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: ProfessionalSupportSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: ProfessionalSupportSectionViewController)
}

// MARK: - ProfessionalSupportSectionViewController

final class ProfessionalSupportSectionViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let scrollViewTopPadding: CGFloat = 8
        static let titleTopPadding: CGFloat = 24
        static let titleHorizontalPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let fieldSpacing: CGFloat = 20
        static let firstFieldTopPadding: CGFloat = 24
        static let crisisCardTopPadding: CGFloat = 16
        static let crisisCardBottomPadding: CGFloat = 24
        static let contentBottomPadding: CGFloat = 40
    }

    // MARK: - Properties

    private var viewModel: ProfessionalSupportSectionViewModel
    weak var delegate: ProfessionalSupportSectionViewControllerDelegate?

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
            title: NSLocalizedString("emotional_bundle_section_professional_support", comment: ""),
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
        label.text = NSLocalizedString("emotional_bundle_professional_support_question", comment: "")
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var crisisResourceCard: CrisisResourceCardView = {
        let card = CrisisResourceCardView()
        card.isHidden = viewModel.crisisResource == nil
        if let resource = viewModel.crisisResource {
            card.configure(with: resource)
        }
        card.parentViewController = self
        return card
    }()

    private lazy var placeField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configure(
            title: NSLocalizedString("emotional_bundle_professional_place", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_professional_place_placeholder", comment: ""),
            text: viewModel.placeName,
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.placeName = text
        }
        return field
    }()

    private lazy var professionalNameField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configure(
            title: NSLocalizedString("emotional_bundle_professional_name", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_professional_name_placeholder", comment: ""),
            text: viewModel.contactName,
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contactName = text
        }
        return field
    }()

    private lazy var emergencyNumberField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configure(
            title: NSLocalizedString("emotional_bundle_professional_phone", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_professional_phone_placeholder", comment: ""),
            text: viewModel.phone,
            maxCharacters: viewModel.maxCharacters,
            keyboardType: .phonePad
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.phone = text
        }
        return field
    }()

    // MARK: - Initialization

    init(viewModel: ProfessionalSupportSectionViewModel) {
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
        contentView.addSubview(crisisResourceCard)
        contentView.addSubview(placeField)
        contentView.addSubview(professionalNameField)
        contentView.addSubview(emergencyNumberField)

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

        crisisResourceCard.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.crisisCardTopPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        placeField.snp.makeConstraints { make in
            if viewModel.crisisResource != nil {
                make.top.equalTo(crisisResourceCard.snp.bottom).offset(Layout.crisisCardBottomPadding)
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(Layout.firstFieldTopPadding)
            }
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        professionalNameField.snp.makeConstraints { make in
            make.top.equalTo(placeField.snp.bottom).offset(Layout.fieldSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        emergencyNumberField.snp.makeConstraints { make in
            make.top.equalTo(professionalNameField.snp.bottom).offset(Layout.fieldSpacing)
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
}
