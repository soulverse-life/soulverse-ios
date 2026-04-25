//
//  DrawingPromptViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

final class DrawingPromptViewController: ViewController {

    private enum Layout {
        static let closeButtonTopInset: CGFloat = 12
        static let horizontalInset: CGFloat = ViewComponentConstants.horizontalPadding
        static let promptTopSpacing: CGFloat = 12
        static let templateTopSpacing: CGFloat = 24
        static let templateBottomSpacing: CGFloat = 32
        static let templateCardCornerRadius: CGFloat = 24
        static let templateImageInset: CGFloat = 36
        static let ctaBottomInset: CGFloat = 24
    }

    // MARK: - Properties

    private let presenter: DrawingPromptPresenterType

    // MARK: - UI

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "naviconClose")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.accessibilityLabel = NSLocalizedString("action_modal_close", comment: "")
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        return button
    }()

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 18, weight: .medium)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private lazy var templateCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Layout.templateCardCornerRadius
        view.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTemplateCard))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var templateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var startDrawButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("start_draw", comment: ""),
            style: .primary,
            delegate: self
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Init

    init(checkinId: String?, recordedEmotion: RecordedEmotion?) {
        self.presenter = DrawingPromptPresenter(
            checkinId: checkinId,
            recordedEmotion: recordedEmotion
        )
        super.init(nibName: nil, bundle: nil)
        self.presenter.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupConstraints()
        startDrawButton.isEnabled = false
        presenter.loadPrompt()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(promptLabel)
        view.addSubview(templateCardView)
        templateCardView.addSubview(templateImageView)
        view.addSubview(startDrawButton)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.closeButtonTopInset)
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.size.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(Layout.promptTopSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }

        startDrawButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Layout.ctaBottomInset)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        templateCardView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(Layout.templateTopSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.lessThanOrEqualTo(startDrawButton.snp.top).offset(-Layout.templateBottomSpacing)
            make.height.equalTo(templateCardView.snp.width)
        }

        templateImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.templateImageInset)
        }
    }

    // MARK: - Actions

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapTemplateCard() {
        startDrawing()
    }

    private func startDrawing() {
        let viewModel = presenter.viewModel
        guard let prompt = viewModel.prompt else { return }
        AppCoordinator.openDrawingCanvas(
            from: self,
            drawingsPrompt: prompt,
            checkinId: viewModel.checkinId
        )
    }
}

// MARK: - DrawingPromptPresenterDelegate

extension DrawingPromptViewController: DrawingPromptPresenterDelegate {

    func didUpdate(viewModel: DrawingPromptViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.promptLabel.text = viewModel.prompt?.artTherapyPrompt
            self.templateImageView.image = viewModel.prompt?.templateImage
            self.startDrawButton.isEnabled = viewModel.prompt != nil
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension DrawingPromptViewController: SoulverseButtonDelegate {

    func clickSoulverseButton(_ button: SoulverseButton) {
        guard button === startDrawButton else { return }
        startDrawing()
    }
}
