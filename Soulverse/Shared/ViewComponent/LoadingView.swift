//
//  LoadingView.swift
//  Soulverse
//

import UIKit
import SnapKit

/// A reusable loading indicator view.
/// Currently uses UIActivityIndicatorView internally, designed to be
/// easily swapped for a custom animation (e.g., Lottie) later.
final class LoadingView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let indicatorSize: CGFloat = 40
    }

    // MARK: - UI Components

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties

    var color: UIColor? {
        get { activityIndicator.color }
        set { activityIndicator.color = newValue }
    }

    var isAnimating: Bool {
        activityIndicator.isAnimating
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
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Public API

    func startAnimating() {
        isHidden = false
        activityIndicator.startAnimating()
    }

    func stopAnimating() {
        activityIndicator.stopAnimating()
        isHidden = true
    }
}
