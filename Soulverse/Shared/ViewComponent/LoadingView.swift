//
//  LoadingView.swift
//  Soulverse
//

import UIKit
import SnapKit
import Lottie

/// A reusable loading indicator view using Lottie animation.
final class LoadingView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let animationSize: CGFloat = 150
    }

    // MARK: - UI Components

    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "stage1_bounce_lottie")
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.backgroundBehavior = .pauseAndRestore
        return view
    }()

    // MARK: - Properties

    var isAnimating: Bool {
        animationView.isAnimationPlaying
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Layout.animationSize)
        }
    }

    // MARK: - Public API

    func startAnimating() {
        isHidden = false
        animationView.play()
    }

    func stopAnimating() {
        animationView.stop()
        isHidden = true
    }
}
