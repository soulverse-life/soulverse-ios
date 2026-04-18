//
//  DetailPlanetView.swift
//  Soulverse
//
//  Large planet view for the check-in detail page.
//  Follows the gradient pattern from CentralPlanetView without E.M.O pet.
//

import SnapKit
import UIKit

final class DetailPlanetView: UIView {

    // MARK: - UI Components

    private lazy var outerGlowView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var outerGlowGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()

    private lazy var haloView: UIView = {
        let haloSize = CheckInDetailLayout.planetDiameter + CheckInDetailLayout.planetHaloExpand * 2
        let view = UIView()
        view.layer.cornerRadius = haloSize / 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var haloGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()

    private lazy var innerPlanetView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = CheckInDetailLayout.planetDiameter / 2
        return view
    }()

    private lazy var emotionGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.3, y: 0.3)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let glowSize = CheckInDetailLayout.planetGlowDiameter
        outerGlowView.layer.cornerRadius = glowSize / 2
        outerGlowGradientLayer.frame = outerGlowView.bounds
        haloGradientLayer.frame = haloView.bounds
        emotionGradientLayer.frame = innerPlanetView.bounds
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear

        addSubview(outerGlowView)
        outerGlowView.layer.insertSublayer(outerGlowGradientLayer, at: 0)
        addSubview(haloView)
        haloView.layer.insertSublayer(haloGradientLayer, at: 0)
        addSubview(innerPlanetView)
        innerPlanetView.layer.insertSublayer(emotionGradientLayer, at: 0)

        let glowSize = CheckInDetailLayout.planetGlowDiameter
        let haloSize = CheckInDetailLayout.planetDiameter + CheckInDetailLayout.planetHaloExpand * 2

        outerGlowView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(glowSize)
        }

        haloView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(haloSize)
        }

        innerPlanetView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(CheckInDetailLayout.planetDiameter)
        }
    }

    // MARK: - Configuration

    func configure(colorHex: String, intensity: Double) {
        let baseColor = (UIColor(hex: colorHex) ?? .themeTextSecondary).withAlphaComponent(CGFloat(intensity))

        // Spotlight gradient: highlight at upper-left → base → dark edge
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let highlightColor = UIColor(red: min(r + 0.4, 1), green: min(g + 0.4, 1), blue: min(b + 0.4, 1), alpha: a)
        let darkerColor = UIColor(red: r * 0.6, green: g * 0.6, blue: b * 0.6, alpha: a)
        emotionGradientLayer.colors = [
            highlightColor.cgColor,
            baseColor.cgColor,
            darkerColor.cgColor
        ]
        emotionGradientLayer.locations = [0.0, 0.45, 1.0]

        // Outer glow
        let glowAlpha = CheckInDetailLayout.planetOuterGlowAlpha
        outerGlowGradientLayer.colors = [
            baseColor.withAlphaComponent(glowAlpha).cgColor,
            baseColor.withAlphaComponent(glowAlpha * 0.5).cgColor,
            UIColor.clear.cgColor
        ]

        // Halo
        let diameter = CheckInDetailLayout.planetDiameter
        let haloSize = diameter + CheckInDetailLayout.planetHaloExpand * 2
        let fadeStart = NSNumber(value: Double(diameter / haloSize))
        haloGradientLayer.colors = [
            baseColor.cgColor,
            baseColor.cgColor,
            UIColor.clear.cgColor
        ]
        haloGradientLayer.locations = [0.0, fadeStart, 1.0]
    }

    // MARK: - Intrinsic Size

    override var intrinsicContentSize: CGSize {
        let size = CheckInDetailLayout.planetGlowDiameter
        return CGSize(width: size, height: size)
    }
}
