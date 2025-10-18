//
//  ToolsViewController.swift
//

import UIKit

class ToolsViewController: ViewController {
    
    private lazy var navigationView: SoulverseNavigationView = {
        let view = SoulverseNavigationView(title: NSLocalizedString("tools", comment: ""))
        return view
    }()
    
    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.backgroundView = nil  // Remove default background to show gradient
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ViewComponentConstants.miniBarHeight - 20.0, right: 0)
        table.refreshControl = UIRefreshControl()
        table.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return table
    }()
    private let presenter = ToolsViewPresenter()
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
        view.addSubview(tableView)
        
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        // self.extendedLayoutIncludesOpaqueBars = true
        // self.edgesForExtendedLayout = .top
    }
    func setupPresenter() {
        presenter.delegate = self
    }
    @objc func pullToRefresh() {
        if !tableView.isDragging {
            presenter.fetchData(isUpdate: true)
        }
    }
}
extension ToolsViewController: UITableViewDataSource, UITableViewDelegate {
    private func getSectionHeaderView(title: String, bottomPadding: CGFloat = 10) -> UIView {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        let headerView = UIView()
        headerView.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = UIFont.projectFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .primaryWhite
        titleLabel.sizeToFit()
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(bottomPadding)
        }
        return headerView
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        presenter.numberOfSectionsOnTableView()
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}
extension ToolsViewController: ToolsViewPresenterDelegate {
    func didUpdate(viewModel: ToolsViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.showLoading = viewModel.isLoading
            weakSelf.tableView.refreshControl?.endRefreshing()
            let top = weakSelf.tableView.adjustedContentInset.top
            let y = weakSelf.tableView.refreshControl!.frame.maxY + top
            weakSelf.tableView.setContentOffset(CGPoint(x: 0, y: -y), animated: true)
            weakSelf.tableView.reloadData()
        }
    }
    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.tableView.reloadSections(index, with: .automatic)
        }
    }
}
extension ToolsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
} 
