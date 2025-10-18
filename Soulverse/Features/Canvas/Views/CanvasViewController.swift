//
//  CanvasViewController.swift
//

import UIKit
import SnapKit

class CanvasViewController: ViewController {
    
    // MARK: - UI Elements
    private lazy var navigationView: SoulverseNavigationView = {
        let view = SoulverseNavigationView(title: NSLocalizedString("canvas", comment: ""))
        return view
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 32
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("canvas_description", comment: "")
        label.font = UIFont.projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var startDrawingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("start_now", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.projectFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startDrawingTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    private var presenter: CanvasViewPresenterType
    
    // MARK: - Lifecycle
    init(presenter: CanvasViewPresenterType = CanvasViewPresenter()) {
        self.presenter = presenter
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(navigationView)
        view.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.addArrangedSubview(startDrawingButton)
    }
    
    private func setupConstraints() {
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        startDrawingButton.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.width.greaterThanOrEqualTo(200)
        }
    }
    
    // MARK: - Actions
    @objc private func startDrawingTapped() {
        AppCoordinator.openDrawingCanvas(from: self)
    }
}

// MARK: - CanvasViewPresenterDelegate
extension CanvasViewController: CanvasViewPresenterDelegate {
    func didUpdate(viewModel: CanvasViewModel) {
        DispatchQueue.main.async { [weak self] in
            // Handle any updates from presenter if needed
        }
    }
    
    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            // Handle section updates if needed
        }
    }
}
