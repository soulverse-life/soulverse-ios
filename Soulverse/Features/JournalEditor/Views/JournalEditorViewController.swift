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
}

final class JournalEditorViewController: ViewController {

    // MARK: - Layout

    private enum Layout {
        static let headerTopOffset: CGFloat = 32
        static let headerHorizontalInset: CGFloat = 26
        static let titleFieldTopOffset: CGFloat = 32
        static let fieldHorizontalInset: CGFloat = 26
        static let titleFieldHeight: CGFloat = 60
        static let titleMaxCharacters: Int = 100
        static let titleToContentSpacing: CGFloat = 16
        static let contentFieldHeight: CGFloat = 200
        static let contentMaxCharacters: Int = 2000
        static let saveButtonBottomInset: CGFloat = 12
        static let drawLinkBottomInset: CGFloat = 16
        static let drawLinkFontSize: CGFloat = 17
        static let drawLinkContentInset: CGFloat = 12
        static let savingOverlayDimAlpha: CGFloat = 0.4
    }

    // MARK: - Properties

    weak var delegate: JournalEditorViewControllerDelegate?

    private let viewModel: JournalEditorViewModel

    /// Exposed for callers that need to chain a follow-up action to the same
    /// check-in (e.g. the draw pivot). Avoids leaking the whole ViewModel.
    var checkinId: String { viewModel.checkinId }

    private let colorHex: String?
    private let colorIntensity: Double
    private let emotionName: String?

    // MARK: - UI Elements

    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("journal_editor_nav_title", comment: ""),
            showBackButton: true
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var headerView: JournalEmotionHeaderView = {
        return JournalEmotionHeaderView(
            colorHex: colorHex ?? "",
            intensity: colorIntensity,
            emotionName: emotionName ?? ""
        )
    }()

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
        var config = UIButton.Configuration.plain()
        config.title = NSLocalizedString("journal_editor_draw_link", comment: "")
        config.baseForegroundColor = .themeTextPrimary
        config.contentInsets = NSDirectionalEdgeInsets(
            top: Layout.drawLinkContentInset,
            leading: Layout.drawLinkContentInset,
            bottom: Layout.drawLinkContentInset,
            trailing: Layout.drawLinkContentInset
        )
        let button = UIButton(configuration: config)
        button.titleLabel?.font = .projectFont(ofSize: Layout.drawLinkFontSize, weight: .semibold)
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
        wireFieldCallbacks()

        viewModel.delegate = self

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
        view.addSubview(navigationView)
        view.addSubview(headerView)
        view.addSubview(titleField)
        view.addSubview(contentField)
        view.addSubview(drawLinkButton)
        view.addSubview(saveButton)
        view.addSubview(savingIndicator)

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom).offset(Layout.headerTopOffset)
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
            maxCharacters: Layout.titleMaxCharacters,
            fieldHeight: Layout.titleFieldHeight
        )
        contentField.configure(
            title: "",
            placeholder: NSLocalizedString("journal_editor_content_placeholder", comment: ""),
            maxCharacters: Layout.contentMaxCharacters,
            fieldHeight: Layout.contentFieldHeight
        )
    }

    // MARK: - State Sync

    private func applyState() {
        saveButton.isEnabled = viewModel.canSave
        // Disable the two action buttons while saving (not the whole view —
        // keep scroll, keyboard dismiss, and back accessible if the request
        // hangs). Double-submit is already gated by viewModel.canSave.
        drawLinkButton.isEnabled = !viewModel.isSaving

        if viewModel.isSaving {
            savingIndicator.startAnimating()
            saveButton.alpha = Layout.savingOverlayDimAlpha
        } else {
            savingIndicator.stopAnimating()
            saveButton.alpha = 1.0
        }
    }

    // MARK: - Actions

    @objc private func drawLinkTapped() {
        delegate?.journalEditorDidRequestDraw(self)
    }

    /// Pops back to the previous screen when pushed onto a nav stack with siblings;
    /// otherwise unwinds the whole modal presentation chain (mirrors
    /// `DrawingReflectionViewController.dismissCascade`).
    private func dismissBack() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }
        var bottomPresenter: UIViewController = self
        while let ancestor = bottomPresenter.presentingViewController {
            bottomPresenter = ancestor
        }
        bottomPresenter.dismiss(animated: true)
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

// MARK: - SoulverseNavigationViewDelegate

extension JournalEditorViewController {
    func navigationViewDidTapBack(_ soulverseNavigationView: SoulverseNavigationView) {
        dismissBack()
    }
}

// MARK: - JournalEditorViewModelDelegate

extension JournalEditorViewController: JournalEditorViewModelDelegate {
    func journalEditorViewModelDidUpdateState(_ viewModel: JournalEditorViewModel) {
        applyState()
    }

    func journalEditorViewModel(_ viewModel: JournalEditorViewModel, didSaveJournalId journalId: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: Notification.JournalDidChange),
            object: nil
        )
        delegate?.journalEditorDidSave(self, journalId: journalId)
    }

    func journalEditorViewModel(_ viewModel: JournalEditorViewModel, didFailWithError error: Error) {
        showSaveFailure()
    }
}
