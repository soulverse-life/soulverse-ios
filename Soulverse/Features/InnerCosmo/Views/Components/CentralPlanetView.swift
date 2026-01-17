//
//  CentralPlanetView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Central planet view with E.M.O pet image and name
class CentralPlanetView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let outerDiameter: CGFloat = 280
        static let innerDiameter: CGFloat = 160
        
        static let emoPetImageSize: CGFloat = 64
        static let emoPetLabelFontSize: CGFloat = 11
        static let emoPetNameFontSize: CGFloat = 11
    }

    // MARK: - UI Components

    private lazy var outerPlanetView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "planet_large")
        imageView.contentMode = .center
        imageView.clipsToBounds = false
        imageView.frame.size = CGSize(width: size, height: size)
        return imageView
    }()


    private lazy var innerPlanetView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var emoPetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "basic_first_level")
        return imageView
    }()

    private lazy var emoPetLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("inner_cosmo_emo_pet", comment: "")
        label.font = UIFont.projectFont(ofSize: Layout.emoPetLabelFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var emoPetNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.emoPetNameFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private let size: CGFloat
    
    // MARK: - Initialization
    init(size: CGFloat) {
        self.size = size
        super.init(frame: .zero)
        
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear

        addSubview(outerPlanetView)
        outerPlanetView.addSubview(innerPlanetView)
        innerPlanetView.addSubview(emoPetImageView)
        innerPlanetView.addSubview(emoPetLabel)
        innerPlanetView.addSubview(emoPetNameLabel)
        
        outerPlanetView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(size)
        }

        innerPlanetView.snp.makeConstraints { make in
            make.center.equalTo(outerPlanetView)
            make.width.height.equalTo(Layout.innerDiameter)
        }

        emoPetImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-8)
            make.width.height.equalTo(Layout.emoPetImageSize)
        }

        emoPetLabel.snp.makeConstraints { make in
            make.top.equalTo(emoPetImageView.snp.bottom)
            make.centerX.equalToSuperview()
        }

        emoPetNameLabel.snp.makeConstraints { make in
            make.top.equalTo(emoPetLabel.snp.bottom)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Configuration

    /// Configure the central planet with E.M.O pet name
    /// - Parameter petName: The name of the E.M.O pet
    func configure(petName: String?) {
        emoPetNameLabel.text = petName ?? "Stark"
    }

    // MARK: - Size

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Layout.outerDiameter, height: Layout.outerDiameter)
    }
}
