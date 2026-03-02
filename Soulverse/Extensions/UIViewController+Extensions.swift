import UIKit
import SnapKit

extension UIViewController {
    static func getLastPresentedViewController() -> UIViewController? {
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        let window = sceneDelegate?.window
        var presentedViewController = window?.rootViewController
        
        while presentedViewController?.presentedViewController != nil {
            presentedViewController = presentedViewController?.presentedViewController
        }
        return presentedViewController
    }
    
    var isVisible: Bool {
        return self.isViewLoaded && self.view.window != nil
    }

    // MARK: - Loading View

    private enum AssociatedKeys {
        nonisolated(unsafe) static var loadingOverlay: UInt8 = 0
    }

    private var loadingView: LoadingView? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.loadingOverlay) as? LoadingView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.loadingOverlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func showLoadingView(below belowSubview: UIView? = nil) {
        guard loadingView == nil else { return }

        let overlay = LoadingView()
        view.addSubview(overlay)
        if let belowSubview = belowSubview {
            view.bringSubviewToFront(belowSubview)
        }
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingView = overlay
        overlay.startAnimating()
    }

    func hideLoadingView() {
        loadingView?.stopAnimating()
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
}
