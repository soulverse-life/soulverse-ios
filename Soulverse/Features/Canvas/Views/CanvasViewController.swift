//
//  CanvasViewController.swift
//

import SnapKit
import UIKit

class CanvasViewController: ViewController {

    // MARK: - UI Elements
    private lazy var navigationView: SoulverseNavigationView = {

        let galleryIcon = UIImage(systemName: "photo")

        let galleryItem = SoulverseNavigationItem.button(
            image: galleryIcon,
            identifier: "gallery"
        ) { [weak self] in
            self?.galleryTapped()
        }

        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("canvas", comment: ""),
            rightItems: [galleryItem]
        )

        let view = SoulverseNavigationView(config: config)
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Canvas Section
    private lazy var canvasSectionView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var canvasDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("canvas_description", comment: "")
        label.font = UIFont.projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Prompt Section
    private lazy var promptTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("prompt", comment: "")
        label.font = UIFont.projectFont(ofSize: 18, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var artTherapyPromptLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var templateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var startDrawingButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("start_draw", comment: ""),
            style: .primary,
            delegate: self
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Properties
    private var presenter: CanvasViewPresenterType
    private var currentPrompt: DrawingsPrompt? {
        didSet {
            updatePromptUI()
        }
    }

    // MARK: - Lifecycle
    init(recordedEmotion: RecordedEmotion? = nil) {
        self.presenter = CanvasViewPresenter(recordedEmotion: recordedEmotion)
        super.init(nibName: nil, bundle: nil)
        self.presenter.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()

        // Load initial prompt after delegate is set
        presenter.loadRandomPrompt()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(navigationView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Canvas Section
        canvasSectionView.addSubview(canvasDescriptionLabel)
        contentStackView.addArrangedSubview(canvasSectionView)

        // Prompt Section (add to stack view in order)
        contentStackView.addArrangedSubview(promptTitleLabel)
        contentStackView.addArrangedSubview(artTherapyPromptLabel)
        contentStackView.addArrangedSubview(templateImageView)

        // Start Drawing Button
        contentStackView.addArrangedSubview(startDrawingButton)

        // Initially hide prompt section until data loads
        promptTitleLabel.isHidden = true
        artTherapyPromptLabel.isHidden = true
        templateImageView.isHidden = true
    }

    private func setupConstraints() {
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(24)
            make.left.right.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
            make.width.equalTo(scrollView).offset(-48)
        }

        // Canvas Section Constraints
        canvasDescriptionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Template Image Constraints
        templateImageView.snp.makeConstraints { make in
            make.height.equalTo(300)
        }

        // Start Drawing Button Constraints
        startDrawingButton.snp.makeConstraints { make in
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func updatePromptUI() {
        guard let prompt = currentPrompt else { return }

        // Show prompt section
        promptTitleLabel.isHidden = false
        artTherapyPromptLabel.isHidden = false

        // Update art therapy prompt
        artTherapyPromptLabel.text = prompt.artTherapyPrompt

        // Update template info
        if let templateName = prompt.templateName, !templateName.isEmpty {
            templateImageView.image = prompt.templateImage
        }
        templateImageView.isHidden = false
    }

}

// MARK: - SoulverseButtonDelegate
extension CanvasViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        AppCoordinator.openDrawingCanvas(from: self, drawingsPrompt: currentPrompt)
    }
}

// MARK: - CanvasViewPresenterDelegate
extension CanvasViewController: CanvasViewPresenterDelegate {
    func didUpdate(viewModel: CanvasViewModel) {
        DispatchQueue.main.async { [weak self] in
            self?.currentPrompt = viewModel.currentPrompt
        }
    }

    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            // Handle section updates if needed
        }
    }
}

// MARK: - Navigation Actions
extension CanvasViewController {
    private func galleryTapped() {
        AppCoordinator.openDrawingGallery(from: self)
    }
}
