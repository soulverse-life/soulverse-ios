//
//  QuestViewController.swift
//

import UIKit

class QuestViewController: ViewController {
    
    private lazy var navigationView: SoulverseNavigationView = {
        let view = SoulverseNavigationView(title: NSLocalizedString("quest", comment: ""))
        return view
    }()
    
    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ViewComponentConstants.miniBarHeight - 20.0, right: 0)
        table.refreshControl = UIRefreshControl()
        table.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return table
    }()
    private let presenter = QuestViewPresenter()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPresenter()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        // Load data when view appears
        presenter.fetchData()
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
        
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = .top
    }
    func setupPresenter() {
        presenter.delegate = self
    }
    @objc func pullToRefresh() {
        presenter.fetchData(isUpdate: true)
    }
}
extension QuestViewController: UITableViewDataSource, UITableViewDelegate {
    private func getSectionHeaderView(title: String, bottomPadding: CGFloat = 10) -> UIView {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        let headerView = UIView()
        headerView.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = UIFont.projectFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .primaryBlack
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
        cell.selectionStyle = .none
        
        // Remove any existing subviews to prevent overlap
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if indexPath.section == 0 {
            // Radar Chart Section
            if let radarData = presenter.loadedModel.radarChartData {
                let radarChartView = QuestRadarChartView()
                radarChartView.configure(with: radarData)
                
                cell.contentView.addSubview(radarChartView)
                radarChartView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                    make.height.equalTo(400) // Fixed height for radar chart
                }
            }
        } else if indexPath.section == 1 {
            // Progress Line Section
            let progressLineView = QuestProgressLineView()
            
            if let lineData = presenter.loadedModel.lineChartData {
                progressLineView.configure(with: lineData)
            }
            // If no data, it will show placeholder state (just line, no dots)
            
            cell.contentView.addSubview(progressLineView)
            progressLineView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(100)
            }
        }
        
        return cell
    }
}
extension QuestViewController: QuestViewPresenterDelegate {
    func didUpdate(viewModel: QuestViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.showLoading = viewModel.isLoading
            
            // End refresh control
            if weakSelf.tableView.refreshControl?.isRefreshing == true {
                weakSelf.tableView.refreshControl?.endRefreshing()
            }
            
            // Reload table data
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
extension QuestViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
} 
