//
//  ViewController.swift
//  KonoSummit
//


import UIKit
import SnapKit
import NVActivityIndicatorView
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {

    var showLoading: Bool = false {
        didSet {
            toggleLoading()
        }
    }
    var loadingIndicator: NVActivityIndicatorView!

    /// Gradient background view - added in init for instant display
    private lazy var gradientBackgroundView: GradientView = {
        let view = GradientView()
        return view
    }()

    var isCurrentTabRootVC: Bool {
        if let tabBarController = self.tabBarController,
           let selectedNav = tabBarController.selectedViewController as? UINavigationController,
           selectedNav.viewControllers.first == self {
            return true
        } else {
            return false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup gradient background immediately
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.frame = view.bounds
        gradientBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.sendSubviewToBack(gradientBackgroundView)

        setupNavigationBar()

        loadingIndicator = NVActivityIndicatorView(frame: CGRect.zero, color: .lightGray)
        loadingIndicator.type = .ballSpinFadeLoader
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }

    }

    func toggleLoading() {
        if showLoading {
            view.bringSubviewToFront(loadingIndicator)
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    private func setupNavigationBar() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navBarAppearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navBarAppearance.backgroundColor = .appThemeColor

        navigationController?.navigationBar.backgroundColor = .appThemeColor
        navigationController?.navigationBar.barTintColor = .appThemeColor
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
}

extension ViewController: SoulverseNavigationViewDelegate {
    // Uses default implementation from protocol extension
}
