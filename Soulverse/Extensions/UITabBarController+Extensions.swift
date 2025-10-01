import UIKit

extension UITabBarController {
    func cleanTitles() {
        guard let items = self.tabBar.items else {
            return
        }
        for item in items {
            item.title = ""
            item.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
}


private let redDotViewTag: Int = 1000
extension UITabBar {
    //MARK: show small red dot
    func showIndicator(on itemIndex: Int) {
        self.removeIndicator(on: itemIndex)
    
        //get total items
        let tabbarItemNums: CGFloat = CGFloat(self.items?.count ?? 4)
    
        // create a little red dot
        //this view can hold anything text image
        let bageView = UIView()
        bageView.tag = itemIndex + redDotViewTag
        bageView.layer.cornerRadius = 4
        bageView.backgroundColor = .primaryOrange
        
        let tabFrame = self.frame
        // determine the position of the small red dot
        let percentX: CGFloat = (CGFloat(itemIndex) + 0.59) / tabbarItemNums
        let xPos: CGFloat = CGFloat(ceilf(Float(percentX * tabFrame.size.width)))
        //let yPos: CGFloat = CGFloat(ceilf(Float(tabFrame.size.height * 0.18)))
        bageView.frame = CGRect(x: xPos - 8, y: 15, width: 8, height: 8)
        self.addSubview(bageView)
        self.bringSubviewToFront(bageView)
    }
  
    //MARK:-hide the red dot
    func hideIndicator(on itemIndex: Int) {
        // remove the little red dot
        self.removeIndicator(on: itemIndex)
    }
  
    //MARK:-remove the red dot
    private func removeIndicator(on itemIndex: Int) {
        // Remove by tag value
        let _ = subviews.map {
            if $0.tag == itemIndex + redDotViewTag {
                $0.removeFromSuperview()
            }
        }
    }
}
