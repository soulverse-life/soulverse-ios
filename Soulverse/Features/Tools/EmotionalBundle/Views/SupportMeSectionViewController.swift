//
//  SupportMeSectionViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

// MARK: - Delegate Protocol

protocol SupportMeSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: SupportMeSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: SupportMeSectionViewController)
}

// MARK: - SupportMeSectionViewController

final class SupportMeSectionViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let scrollViewTopPadding: CGFloat = 8
        static let titleTopPadding: CGFloat = 24
        static let titleHorizontalPadding: CGFloat = 24
        static let titleFontSize: CGFloat = 28
        static let iconTopPadding: CGFloat = 24
        static let iconSize: CGFloat = 36
        static let iconToTitleSpacing: CGFloat = 12
        static let contactGroupSpacing: CGFloat = 32
        static let fieldSpacing: CGFloat = 16
        static let firstFieldTopPadding: CGFloat = 24
        static let contactHeaderFontSize: CGFloat = 16
        static let contactHeaderBottomSpacing: CGFloat = 12
        static let contentBottomPadding: CGFloat = 40
    }

    // MARK: - Properties

    private var viewModel: SupportMeSectionViewModel
    weak var delegate: SupportMeSectionViewControllerDelegate?

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let saveItem = SoulverseNavigationItem.button(
            image: UIImage(systemName: "checkmark"),
            identifier: "save"
        ) { [weak self] in
            self?.handleSave()
        }
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("emotional_bundle_section_support_me", comment: ""),
            showBackButton: true,
            rightItems: [saveItem]
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var sectionIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: EmotionalBundleSection.supportMe.iconName)
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
        label.text = NSLocalizedString("emotional_bundle_support_me_question", comment: "")
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    // Contact 1 fields
    private lazy var contact1HeaderLabel: UILabel = {
        let label = UILabel()
        label.text = String(format: NSLocalizedString("emotional_bundle_contact_label", comment: ""), 1)
        label.font = .projectFont(ofSize: Layout.contactHeaderFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var contact1NameField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_name", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_name_placeholder", comment: ""),
            text: viewModel.contacts[0].name,
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[0].name = text
        }
        return field
    }()

    private lazy var contact1PhoneField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_phone", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_phone_placeholder", comment: ""),
            text: viewModel.contacts[0].phone,
            maxCharacters: viewModel.maxCharacters,
            keyboardType: .phonePad
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[0].phone = text
        }
        return field
    }()

    private lazy var contact1EmailField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_email", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_email_placeholder", comment: ""),
            text: viewModel.contacts[0].email,
            maxCharacters: viewModel.maxCharacters,
            keyboardType: .emailAddress
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[0].email = text
        }
        return field
    }()

    private lazy var contact1RelationshipField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_relationship", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_relationship_placeholder", comment: ""),
            text: viewModel.contacts[0].relationship,
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[0].relationship = text
        }
        return field
    }()

    // Contact 2 fields
    private lazy var contact2HeaderLabel: UILabel = {
        let label = UILabel()
        label.text = String(format: NSLocalizedString("emotional_bundle_contact_label", comment: ""), 2)
        label.font = .projectFont(ofSize: Layout.contactHeaderFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var contact2NameField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_name", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_name_placeholder", comment: ""),
            text: viewModel.contacts[1].name,
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[1].name = text
        }
        return field
    }()

    private lazy var contact2PhoneField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_phone", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_phone_placeholder", comment: ""),
            text: viewModel.contacts[1].phone,
            maxCharacters: viewModel.maxCharacters,
            keyboardType: .phonePad
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[1].phone = text
        }
        return field
    }()

    private lazy var contact2EmailField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_email", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_email_placeholder", comment: ""),
            text: viewModel.contacts[1].email,
            maxCharacters: viewModel.maxCharacters,
            keyboardType: .emailAddress
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[1].email = text
        }
        return field
    }()

    private lazy var contact2RelationshipField: BundleFormFieldView = {
        let field = BundleFormFieldView()
        field.configureLabeled(
            inlineTitle: NSLocalizedString("emotional_bundle_contact_relationship", comment: ""),
            placeholder: NSLocalizedString("emotional_bundle_contact_relationship_placeholder", comment: ""),
            text: viewModel.contacts[1].relationship,
            maxCharacters: viewModel.maxCharacters
        )
        field.onTextChanged = { [weak self] text in
            self?.viewModel.contacts[1].relationship = text
        }
        return field
    }()

    // MARK: - Initialization

    init(viewModel: SupportMeSectionViewModel) {
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

        // Contact 1
        contentView.addSubview(contact1HeaderLabel)
        contentView.addSubview(contact1NameField)
        contentView.addSubview(contact1PhoneField)
        contentView.addSubview(contact1EmailField)
        contentView.addSubview(contact1RelationshipField)

        // Contact 2
        contentView.addSubview(contact2HeaderLabel)
        contentView.addSubview(contact2NameField)
        contentView.addSubview(contact2PhoneField)
        contentView.addSubview(contact2EmailField)
        contentView.addSubview(contact2RelationshipField)

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

        // Contact 1
        contact1HeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.firstFieldTopPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact1NameField.snp.makeConstraints { make in
            make.top.equalTo(contact1HeaderLabel.snp.bottom).offset(Layout.contactHeaderBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact1PhoneField.snp.makeConstraints { make in
            make.top.equalTo(contact1NameField.snp.bottom).offset(Layout.fieldSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact1EmailField.snp.makeConstraints { make in
            make.top.equalTo(contact1PhoneField.snp.bottom).offset(Layout.fieldSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact1RelationshipField.snp.makeConstraints { make in
            make.top.equalTo(contact1EmailField.snp.bottom).offset(Layout.fieldSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        // Contact 2
        contact2HeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(contact1RelationshipField.snp.bottom).offset(Layout.contactGroupSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact2NameField.snp.makeConstraints { make in
            make.top.equalTo(contact2HeaderLabel.snp.bottom).offset(Layout.contactHeaderBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact2PhoneField.snp.makeConstraints { make in
            make.top.equalTo(contact2NameField.snp.bottom).offset(Layout.fieldSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact2EmailField.snp.makeConstraints { make in
            make.top.equalTo(contact2PhoneField.snp.bottom).offset(Layout.fieldSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        contact2RelationshipField.snp.makeConstraints { make in
            make.top.equalTo(contact2EmailField.snp.bottom).offset(Layout.fieldSpacing)
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
