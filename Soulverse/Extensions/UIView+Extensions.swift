import Foundation
import UIKit

extension UIView {

    func dropShadow() {
        layer.shadowOffset = CGSize(width: 2, height: 3)
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
        layer.shadowOpacity = 0.16
    }
}
