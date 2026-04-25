//
//  DrawingReflectionViewController.swift
//  Soulverse
//
//  Lets the user record a written reflection for a drawing they just saved
//  (or an existing drawing whose reflection was deferred). The reflection
//  answer is stored on the drawing document itself.
//

import Kingfisher
import SnapKit
import UIKit

// MARK: - Config

/// Inputs needed to display the reflection screen. `drawingImage` is used
/// when the screen is opened right after save (image already in memory);
/// `drawingImageURL` is used when re-entering from a list view.
struct DrawingReflectionConfig {
    let drawingId: String
    let drawingImage: UIImage?
    let drawingImageURL: String?
    let reflectiveQuestion: String
    let reflectiveAnswer: String?
}

final class DrawingReflectionViewController: UIViewController {

    // MARK: - Layout

    private enum Layout {
        static let horizontalPadding: CGFloat = 24
        static let verticalSpacing: CGFloat = 16
        static let imageCardCornerRadius: CGFloat = 16
        static let imageCardHeight: CGFloat = 220
        static let imageCardWidth: CGFloat = 160
        static let chatBubbleCornerRadius: CGFloat = 16
        static let chatBubblePadding: CGFloat = 12
        static let chatPetSize: CGFloat = 54
        static let chatPetSpacing: CGFloat = 8
        static let inputCornerRadius: CGFloat = 16
        static let inputMinHeight: CGFloat = 120
        static let inputPadding: CGFloat = 12
        static let submitButtonHeight: CGFloat = 50
        static let cancelButtonTopSpacing: CGFloat = 4
        static let cancelButtonBottomInset: CGFloat = 16
        static let petImageName: String = "basic_first_level"
    }

    // MARK: - Properties

    private let config: DrawingReflectionConfig
    private let presenter: DrawingReflectionPresenterType

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let navConfig = SoulverseNavigationConfig(
            title: NSLocalizedString("drawing_reflection_title", comment: ""),
            showBackButton: true,
            backButtonAssetName: "naviconClose",
            backButtonFallbackSymbol: "xmark"
        )
        let view = SoulverseNavigationView(config: navConfig)
        view.delegate = self
        return view
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.verticalSpacing
        return stack
    }()

    private let imageCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Layout.imageCardCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let drawingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private let chatRowContainer = UIView()

    private let chatBubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .themeChatBubbleBackground
        view.layer.cornerRadius = Layout.chatBubbleCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private let petImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: Layout.petImageName)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let inputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .themeChatBubbleBackground
        view.layer.cornerRadius = Layout.inputCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.font = .projectFont(ofSize: 16, weight: .regular)
        textView.textColor = .themeTextPrimary
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(
            top: Layout.inputPadding,
            left: Layout.inputPadding,
            bottom: Layout.inputPadding,
            right: Layout.inputPadding
        )
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("drawing_reflection_input_placeholder", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var submitButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("drawing_reflection_submit", comment: ""),
            style: .primary,
            delegate: self
        )
        button.isEnabled = false
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("drawing_reflection_cancel", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.themeTextPrimary, for: .normal)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(config: DrawingReflectionConfig,
         presenter: DrawingReflectionPresenterType = DrawingReflectionPresenter()) {
        self.config = config
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
        view.backgroundColor = .themeModalBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupConstraints()
        applyConfig()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(navigationView)
        view.addSubview(scrollView)
        view.addSubview(submitButton)
        view.addSubview(cancelButton)

        scrollView.addSubview(contentStack)

        imageCardView.addSubview(drawingImageView)
        contentStack.addArrangedSubview(imageCardView)

        chatRowContainer.addSubview(chatBubbleView)
        chatRowContainer.addSubview(petImageView)
        chatBubbleView.addSubview(questionLabel)
        contentStack.addArrangedSubview(chatRowContainer)

        inputContainer.addSubview(inputTextView)
        inputContainer.addSubview(placeholderLabel)
        contentStack.addArrangedSubview(inputContainer)
    }

    private func setupConstraints() {
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.navigationBarHeight)
        }

        cancelButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Layout.cancelButtonBottomInset)
            make.centerX.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        submitButton.snp.makeConstraints { make in
            make.bottom.equalTo(cancelButton.snp.top).offset(-Layout.cancelButtonTopSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
            make.height.equalTo(Layout.submitButtonHeight)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(submitButton.snp.top).offset(-Layout.verticalSpacing)
        }

        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.verticalSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
            make.width.equalTo(scrollView).offset(-Layout.horizontalPadding * 2)
        }

        imageCardView.snp.makeConstraints { make in
            make.width.equalTo(Layout.imageCardWidth)
            make.height.equalTo(Layout.imageCardHeight)
        }
        drawingImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.chatBubblePadding)
        }

        chatRowContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
        petImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.chatPetSize)
            make.trailing.equalToSuperview()
            make.centerY.equalTo(chatBubbleView)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        chatBubbleView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(petImageView.snp.leading).offset(-Layout.chatPetSpacing)
        }
        questionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.chatBubblePadding)
        }

        inputContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(Layout.inputMinHeight)
        }
        inputTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.inputPadding + 4)
            make.leading.equalToSuperview().inset(Layout.inputPadding)
            make.trailing.lessThanOrEqualToSuperview().inset(Layout.inputPadding)
        }
    }

    private func applyConfig() {
        questionLabel.text = config.reflectiveQuestion
        if let image = config.drawingImage {
            drawingImageView.image = image
        } else if let urlString = config.drawingImageURL,
                  let url = URL(string: urlString) {
            drawingImageView.kf.setImage(with: url)
        }
        if let existing = config.reflectiveAnswer, !existing.isEmpty {
            inputTextView.text = existing
        }
        updatePlaceholderVisibility()
        updateSubmitEnabled()
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !inputTextView.text.isEmpty
    }

    private func updateSubmitEnabled() {
        let trimmed = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        submitButton.isEnabled = !trimmed.isEmpty
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismissCascade()
    }

    private func submitTapped() {
        let answer = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return }
        view.endEditing(true)
        presenter.submitReflection(drawingId: config.drawingId, answer: answer)
    }

    /// Walks the presenter chain so that closing this VC also unwinds any
    /// other modals that were presented above the original entry view
    /// (e.g. drawing prompt + drawing canvas wrapped in modals).
    private func dismissCascade() {
        var bottomPresenter: UIViewController = self
        while let presenter = bottomPresenter.presentingViewController {
            bottomPresenter = presenter
        }
        bottomPresenter.dismiss(animated: true)
    }
}

// MARK: - SoulverseButtonDelegate

extension DrawingReflectionViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        submitTapped()
    }
}

// MARK: - UITextViewDelegate

extension DrawingReflectionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateSubmitEnabled()
    }
}

// MARK: - SoulverseNavigationViewDelegate

extension DrawingReflectionViewController: SoulverseNavigationViewDelegate {
    func navigationViewDidTapBack(_ soulverseNavigationView: SoulverseNavigationView) {
        dismissCascade()
    }
}

// MARK: - DrawingReflectionPresenterDelegate

extension DrawingReflectionViewController: DrawingReflectionPresenterDelegate {

    func didStartSavingReflection() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.showLoadingView(below: self.navigationView)
            self.submitButton.isEnabled = false
        }
    }

    func didFinishSavingReflection(answer: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hideLoadingView()
            self.dismissCascade()
        }
    }

    func didFailSavingReflection(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hideLoadingView()
            self.updateSubmitEnabled()

            let alert = UIAlertController(
                title: NSLocalizedString("drawing_reflection_save_error_title", comment: ""),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .default
            ))
            self.present(alert, animated: true)
        }
    }
}
