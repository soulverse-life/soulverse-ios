//
//  DrawingResultViewController.swift
//

import UIKit
import SnapKit

class DrawingResultViewController: UIViewController {

    // MARK: - UI Components
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var drawingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var ctaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Write journal", for: .normal)
        button.titleLabel?.font = UIFont.projectFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        // Placeholder - no action for now
        return button
    }()

    // MARK: - Properties
    private let drawingImage: UIImage

    // MARK: - Lifecycle
    init(drawingImage: UIImage) {
        self.drawingImage = drawingImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadImage()
    }

    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        view.addSubview(closeButton)
        view.addSubview(drawingImageView)
        view.addSubview(ctaButton)

    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        drawingImageView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.lessThanOrEqualTo(ctaButton.snp.top).offset(-20)
        }

        ctaButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }

    // MARK: - Helper Methods
    private func loadImage() {
        drawingImageView.image = drawingImage
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
