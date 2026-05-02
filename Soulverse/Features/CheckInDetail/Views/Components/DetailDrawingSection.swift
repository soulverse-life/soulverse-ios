//
//  DetailDrawingSection.swift
//  Soulverse
//
//  Drawing image (no card chrome) or "Start to Draw" CTA when no drawing exists.
//  Reflection content lives in DetailReflectionSection.
//

import Kingfisher
import SnapKit
import UIKit

protocol DetailDrawingSectionDelegate: AnyObject {
    func detailDrawingSectionDidTapCreate(_ section: DetailDrawingSection, checkinId: String?)
}

final class DetailDrawingSection: UIView {

    // MARK: - State

    private enum State {
        case loading
        case content
        case empty
    }

    // MARK: - Properties

    weak var delegate: DetailDrawingSectionDelegate?
    private var checkinId: String?
    private var currentState: State?

    // MARK: - UI Components

    /// Single container whose child is swapped between loading / image / CTA.
    private let bodyContainer = UIView()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .themeTextSecondary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var drawingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = CheckInDetailLayout.drawingImageCornerRadius
        imageView.backgroundColor = .white
        return imageView
    }()

    private lazy var ctaButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("checkin_detail_draw_cta", comment: ""),
            style: .primary,
            delegate: self
        )
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(bodyContainer)
        bodyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - State Transitions

    private func transition(to state: State) {
        guard currentState != state else { return }
        currentState = state

        // Remove previous content
        bodyContainer.subviews.forEach { $0.removeFromSuperview() }

        switch state {
        case .loading:
            installLoading()
        case .content:
            installImage()
        case .empty:
            installCTA()
        }
    }

    private func installLoading() {
        bodyContainer.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(CheckInDetailLayout.drawingImageHeight)
        }
        loadingIndicator.startAnimating()
    }

    private func installImage() {
        bodyContainer.addSubview(drawingImageView)
        drawingImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(CheckInDetailLayout.drawingImageWidth)
            make.height.equalTo(CheckInDetailLayout.drawingImageHeight)
        }
    }

    private func installCTA() {
        bodyContainer.addSubview(ctaButton)
        ctaButton.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview()
            make.height.equalTo(CheckInDetailLayout.ctaButtonHeight)
        }
    }

    // MARK: - Public API

    func showLoading() {
        transition(to: .loading)
    }

    /// Configure with the drawing image URL (or nil for empty/CTA state).
    func configure(imageURL: String?, checkinId: String?) {
        self.checkinId = checkinId

        if let imageURL = imageURL, let url = URL(string: imageURL) {
            transition(to: .content)
            drawingImageView.kf.setImage(with: url)
        } else {
            transition(to: .empty)
        }
    }

}

// MARK: - SoulverseButtonDelegate

extension DetailDrawingSection: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        delegate?.detailDrawingSectionDidTapCreate(self, checkinId: checkinId)
    }
}
