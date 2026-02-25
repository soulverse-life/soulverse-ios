//
//  DrawingGalleryCell.swift
//  Soulverse
//

import UIKit
import SnapKit
import Kingfisher

final class DrawingGalleryCell: UICollectionViewCell {

    static let reuseIdentifier = "DrawingGalleryCell"

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 12
    }

    // MARK: - UI Components

    private let drawingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .themeCardBackground
        imageView.layer.cornerRadius = Layout.cornerRadius
        return imageView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        drawingImageView.kf.cancelDownloadTask()
        drawingImageView.image = nil
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(drawingImageView)
        drawingImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with drawing: DrawingModel) {
        guard let url = URL(string: drawing.imageURL) else { return }
        drawingImageView.kf.setImage(with: url)
    }
}
