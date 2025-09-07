//
//  SoulverseTabBar.swift
//  Soulverse
//
//  Created by mingshing on 2021/8/13.
//

import UIKit

protocol SoulverseTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: SoulverseTabBarController, didSelectTab tab: SoulverseTab)
}

enum SoulverseTab: Int, CaseIterable {
    case innerCosmo = 0
    case insight
    case canvas
    case tools
    case quest
    
    var viewController: UIViewController {
        switch self {
        case .innerCosmo:
            return InnerCosmoViewController()
        case .insight:
            return InsightViewController()
        case .canvas:
            return CanvasViewController()
        case .tools:
            return ToolsViewController()
        case .quest:
            return QuestViewController()
        }
    }
    
    var tabTitle: String {
        switch self {
        case .innerCosmo:
            return NSLocalizedString("inner_cosmo", comment: "")
        case .insight:
            return NSLocalizedString("insight", comment: "")
        case .canvas:
            return NSLocalizedString("canvas", comment: "")
        case .tools:
            return NSLocalizedString("tools", comment: "")
        case .quest:
            return NSLocalizedString("quest", comment: "")
        }
    }
    
    var tabImage: UIImage? {
        switch self {
        case .innerCosmo:
            return UIImage(named: "tabIconInnerCosmos")
        case .insight:
            return UIImage(named: "tabIconInsight")
        case .canvas:
            return UIImage(named: "tabIconCanvas")
        case .tools:
            return UIImage(named: "tabIconTool")
        case .quest:
            return UIImage(named: "tabIconQuest")
        }
    }
    
    var tabSelectedImage: UIImage? {
        switch self {
        case .innerCosmo:
            return UIImage(named: "tabIconInnerCosmos")?.withRenderingMode(.alwaysOriginal)
        case .insight:
            return UIImage(named: "tabIconInsight")?.withRenderingMode(.alwaysOriginal)
        case .canvas:
            return UIImage(named: "tabIconCanvas")?.withRenderingMode(.alwaysOriginal)
        case .tools:
            return UIImage(named: "tabIconTool")?.withRenderingMode(.alwaysOriginal)
        case .quest:
            return UIImage(named: "tabIconQuest")?.withRenderingMode(.alwaysOriginal)
        }
    }
}

class SoulverseTabBarController: UITabBarController {
    
    weak var soulverseDelegate: SoulverseTabBarDelegate?
    private let redDotViewTag: Int = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTabs()
        delegate = self
    }
    
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowImage = UIImage()
        appearance.backgroundImage = UIImage()
        appearance.shadowColor = .clear
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .black
    }
    
    private func setupTabs() {
        var navControllers: [UINavigationController] = []
        
        for tab in SoulverseTab.allCases {
            let viewController = tab.viewController
            viewController.tabBarItem = UITabBarItem(
                title: tab.tabTitle,
                image: tab.tabImage,
                selectedImage: tab.tabSelectedImage
            )
            viewController.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            
            let navController = UINavigationController(rootViewController: viewController)
            navControllers.append(navController)
        }
        
        setViewControllers(navControllers, animated: false)
    }
    
    // MARK: - Badge Management
    func showBadge(on tabIndex: Int) {
        tabBar.soulverseShowIndicator(on: tabIndex)
    }
    
    func hideBadge(on tabIndex: Int) {
        tabBar.soulverseHideIndicator(on: tabIndex)
    }
}

// MARK: - UITabBarControllerDelegate
extension SoulverseTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedIndex = viewControllers?.firstIndex(of: viewController),
              let tab = SoulverseTab(rawValue: selectedIndex) else { return }
        
        soulverseDelegate?.tabBar(self, didSelectTab: tab)
    }
}

// MARK: - UITabBar Extensions (Badge Support for Soulverse)
private extension UITabBar {
    func soulverseShowIndicator(on itemIndex: Int) {
        soulverseRemoveIndicator(on: itemIndex)
        
        let tabbarItemNums: CGFloat = CGFloat(items?.count ?? 5)
        let bageView = UIView()
        bageView.tag = itemIndex + 2000 // Different tag to avoid conflicts
        bageView.layer.cornerRadius = 4
        bageView.backgroundColor = .primaryOrange
        
        let tabFrame = frame
        let percentX: CGFloat = (CGFloat(itemIndex) + 0.59) / tabbarItemNums
        let xPos: CGFloat = CGFloat(ceilf(Float(percentX * tabFrame.size.width)))
        bageView.frame = CGRect(x: xPos - 8, y: 15, width: 8, height: 8)
        
        addSubview(bageView)
        bringSubviewToFront(bageView)
    }
    
    func soulverseHideIndicator(on itemIndex: Int) {
        soulverseRemoveIndicator(on: itemIndex)
    }
    
    func soulverseRemoveIndicator(on itemIndex: Int) {
        subviews.forEach {
            if $0.tag == itemIndex + 2000 {
                $0.removeFromSuperview()
            }
        }
    }
}
