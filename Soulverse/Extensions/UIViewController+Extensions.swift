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

    func showLoadingView(below belowSubview: UIView? = nil) {
        guard !view.subviews.contains(where: { $0 is LoadingView }) else { return }

        let loadingView = LoadingView()
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingView.startAnimating()
    }

    func hideLoadingView() {
        guard let loadingView = view.subviews.first(where: { $0 is LoadingView }) as? LoadingView else { return }
        loadingView.stopAnimating()
        loadingView.removeFromSuperview()
    }
}
