//
//  JournalEditorViewController.swift
//  Soulverse
//
//  Lets the user write and save a journal entry attached to a mood check-in.
//  Hosts the JournalEditorViewModel directly (no separate Presenter for this
//  simple form) and exposes a delegate so callers can react to save / draw / back.
//

import UIKit
import SnapKit

protocol JournalEditorViewControllerDelegate: AnyObject {
    func journalEditorDidSave(_ vc: JournalEditorViewController, journalId: String)
    func journalEditorDidRequestDraw(_ vc: JournalEditorViewController)
    func journalEditorDidTapBack(_ vc: JournalEditorViewController)
}

final class JournalEditorViewController: ViewController {

    // MARK: - Layout

    private enum Layout {
        static let navBarTopOffset: CGFloat = 16
        static let navBarHorizontalInset: CGFloat = 16
        static let navTitleFontSize: CGFloat = 17
        static let headerTopOffset: CGFloat = 32
        static let headerHorizontalInset: CGFloat = 26
        static let titleFieldTopOffset: CGFloat = 32
        static let fieldHorizontalInset: CGFloat = 26
        static let titleFieldHeight: CGFloat = 60
        static let titleToContentSpacing: CGFloat = 16
        static let contentFieldHeight: CGFloat = 200
        static let saveButtonBottomInset: CGFloat = 12
        static let drawLinkBottomInset: CGFloat = 16
        static let drawLinkFontSize: CGFloat = 17
        static let drawLinkContentInset: CGFloat = 12
        static let savingOverlayDimAlpha: CGFloat = 0.4
    }

    // MARK: - Properties

    weak var delegate: JournalEditorViewControllerDelegate?

    let viewModel: JournalEditorViewModel

    private let colorHex: String?
    private let colorIntensity: Double
    private let emotionName: String?

    // MARK: - UI Elements

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            button.setImage(UIImage(named: "naviconBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .center
            button.imageView?.clipsToBounds = false
            button.clipsToBounds = false
        } else {
            button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            button.tintColor = .themeTextPrimary
        }
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var navTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("journal_editor_nav_title", comment: "")
        label.font = .projectFont(ofSize: Layout.navTitleFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private let headerView = JournalEmotionHeaderView()

    private let titleField = SoulverseFormFieldView()
    private let contentField = SoulverseFormFieldView()

    private lazy var saveButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("journal_editor_save_button", comment: ""),
            style: .primary,
            delegate: self
        )
        return button
    }()

    private lazy var savingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .themeTextPrimary
        return indicator
    }()

    private lazy var drawLinkButton: UIButton = {
        let button: UIButton
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = NSLocalizedString("journal_editor_draw_link", comment: "")
            config.baseForegroundColor = .themeTextPrimary
            config.contentInsets = NSDirectionalEdgeInsets(
                top: Layout.drawLinkContentInset,
                leading: Layout.drawLinkContentInset,
                bottom: Layout.drawLinkContentInset,
                trailing: Layout.drawLinkContentInset
            )
            button = UIButton(configuration: config)
            button.titleLabel?.font = .projectFont(ofSize: Layout.drawLinkFontSize, weight: .semibold)
        } else {
            button = UIButton(type: .system)
            button.setTitle(NSLocalizedString("journal_editor_draw_link", comment: ""), for: .normal)
            button.titleLabel?.font = .projectFont(ofSize: Layout.drawLinkFontSize, weight: .semibold)
            button.setTitleColor(.themeTextPrimary, for: .normal)
        }
        button.addTarget(self, action: #selector(drawLinkTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    init(checkinId: String, colorHex: String?, colorIntensity: Double, emotionName: String?) {
        self.viewModel = JournalEditorViewModel(checkinId: checkinId)
        self.colorHex = colorHex
        self.colorIntensity = colorIntensity
        self.emotionName = emotionName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    private var priorNavigationBarHidden: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
        wireFieldCallbacks()

        viewModel.delegate = self

        headerView.configure(
            colorHex: colorHex,
            intensity: colorIntensity,
            emotionName: emotionName
        )

        configureFields()
        applyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if priorNavigationBarHidden == nil {
            priorNavigationBarHidden = navigationController?.isNavigationBarHidden
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let prior = priorNavigationBarHidden, prior == false {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(navTitleLabel)
        view.addSubview(headerView)
        view.addSubview(titleField)
        view.addSubview(contentField)
        view.addSubview(drawLinkButton)
        view.addSubview(saveButton)
        view.addSubview(savingIndicator)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.navBarTopOffset)
            make.left.equalToSuperview().offset(Layout.navBarHorizontalInset)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        navTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(backButton.snp.right)
            make.right.lessThanOrEqualToSuperview().offset(-Layout.navBarHorizontalInset)
        }

        headerView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(Layout.headerTopOffset)
            make.left.right.equalToSuperview().inset(Layout.headerHorizontalInset)
        }

        titleField.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(Layout.titleFieldTopOffset)
            make.left.right.equalToSuperview().inset(Layout.fieldHorizontalInset)
        }

        contentField.snp.makeConstraints { make in
            make.top.equalTo(titleField.snp.bottom).offset(Layout.titleToContentSpacing)
            make.left.right.equalToSuperview().inset(Layout.fieldHorizontalInset)
        }

        saveButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.fieldHorizontalInset)
            make.bottom.equalTo(drawLinkButton.snp.top).offset(-Layout.saveButtonBottomInset)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        drawLinkButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Layout.drawLinkBottomInset)
        }

        savingIndicator.snp.makeConstraints { make in
            make.center.equalTo(saveButton)
        }
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func wireFieldCallbacks() {
        titleField.onTextChanged = { [weak self] text in
            self?.viewModel.updateTitle(text)
        }
        contentField.onTextChanged = { [weak self] text in
            self?.viewModel.updateContent(text)
        }
    }

    private func configureFields() {
        titleField.configure(
            title: "",
            placeholder: NSLocalizedString("journal_editor_title_placeholder", comment: ""),
            fieldHeight: Layout.titleFieldHeight
        )
        contentField.configure(
            title: "",
            placeholder: NSLocalizedString("journal_editor_content_placeholder", comment: ""),
            fieldHeight: Layout.contentFieldHeight
        )
    }

    // MARK: - State Sync

    private func applyState() {
        saveButton.isEnabled = viewModel.canSave

        if viewModel.isSaving {
            savingIndicator.startAnimating()
            saveButton.alpha = Layout.savingOverlayDimAlpha
            view.isUserInteractionEnabled = false
        } else {
            savingIndicator.stopAnimating()
            saveButton.alpha = 1.0
            view.isUserInteractionEnabled = true
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.journalEditorDidTapBack(self)
    }

    @objc private func drawLinkTapped() {
        delegate?.journalEditorDidRequestDraw(self)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showSaveFailure() {
        SummitAlertView.shared.show(
            title: "",
            message: NSLocalizedString("journal_editor_save_failed", comment: ""),
            actions: [
                SummitAlertAction(
                    title: NSLocalizedString("emotional_bundle_crisis_ok", comment: ""),
                    style: .default,
                    isPreferredAction: true,
                    handler: nil
                )
            ]
        )
    }
}

// MARK: - SoulverseButtonDelegate

extension JournalEditorViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard button === saveButton else { return }
        view.endEditing(true)
        viewModel.submit()
    }
}

// MARK: - JournalEditorViewModelDelegate

extension JournalEditorViewController: JournalEditorViewModelDelegate {
    func journalEditorViewModelDidUpdateState(_ viewModel: JournalEditorViewModel) {
        applyState()
    }

    func journalEditorViewModel(_ viewModel: JournalEditorViewModel, didSaveJournalId journalId: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: Notification.MoodCheckInCreated),
            object: nil
        )
        delegate?.journalEditorDidSave(self, journalId: journalId)
    }

    func journalEditorViewModel(_ viewModel: JournalEditorViewModel, didFailWithError error: Error) {
        showSaveFailure()
    }
}
