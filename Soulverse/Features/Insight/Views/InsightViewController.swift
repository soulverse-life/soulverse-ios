//
//  InsightViewController.swift
//

import UIKit

class InsightViewController: ViewController {
    
    private lazy var navigationView: SoulverseNavigationView = {
        let view = SoulverseNavigationView(title: NSLocalizedString("insight", comment: ""))
        return view
    }()
    
    private let presenter = InsightViewPresenter()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPresenter()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    func setupView() {
        // Hide default navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(navigationView)
        
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
        
    }
    func setupPresenter() {
        presenter.delegate = self
    }
}
extension InsightViewController: InsightViewPresenterDelegate {
    func didUpdate(viewModel: InsightViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.showLoading = viewModel.isLoading
        }
    }
    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
        }
    }
}
extension InsightViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
} 
