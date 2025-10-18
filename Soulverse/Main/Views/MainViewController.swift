//
//  MainViewController.swift
//  Soulverse
//

import UIKit

class MainViewController: SoulverseTabBarController {

    /// Persistent gradient background - prevents blinking during tab switches
    private lazy var persistentGradientView: GradientView = {
        let view = GradientView()
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPersistentGradient()
        soulverseDelegate = self
    }

    private func setupPersistentGradient() {
        // Set view background to clear to ensure gradient is visible
        view.backgroundColor = .clear

        // Insert gradient at the very back of the view hierarchy
        view.insertSubview(persistentGradientView, at: 0)
        persistentGradientView.frame = view.bounds
        persistentGradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure gradient stays at the back
        view.sendSubviewToBack(persistentGradientView)
    }
}

// MARK: - SoulverseTabBarDelegate
extension MainViewController: SoulverseTabBarDelegate {
    func tabBar(_ tabBar: SoulverseTabBarController, didSelectTab tab: SoulverseTab) {
        // Handle tab selection if needed
        print("Selected tab: \(tab)")
    }
}