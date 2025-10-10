//
//  NotificationViewController.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/14.
//

import UIKit


class NotificationViewController: ViewController {
    

    // MARK:- Views
    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: DeviceConstants.width, height: 0), style: .grouped)
        table.backgroundColor = .backgroundBlack
        table.separatorStyle = .none
        table.register(
            NotificationItemTableViewCell.self,
            forCellReuseIdentifier: String(describing: NotificationItemTableViewCell.self)
        )
        table.delegate = self
        table.dataSource = self
        
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ViewComponentConstants.miniBarHeight - 20.0, right: 0)
        return table
    }()

    private lazy var emptyView: NotificationEmptyView = {
        let view = NotificationEmptyView(delegate: self)
        
        return view
    }()
    
    private lazy var askPermissionHeaderView: UIView = {
       
        let button = UIButton()
        button.setTitle(NSLocalizedString("notification_ask_permission_action_title", comment: ""), for: .normal)
        button.setTitleColor(.primaryBlack, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 12.0, weight: .bold)
        button.backgroundColor = .themeMainColor
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(tapAskPermissionBtn), for: .touchUpInside)
    
        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.font = .projectFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .primaryWhite
        descriptionLabel.text = NSLocalizedString("notification_ask_permission_action_description", comment: "")
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: DeviceConstants.width, height: 80))
        view.backgroundColor = .subBackgroundBlack
        view.addSubview(button)
        button.snp.makeConstraints { make in
            
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(20)
            make.width.equalTo(72)
            make.height.equalTo(ViewComponentConstants.smallActionButtonHeight)
        }
        
        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(30)
            make.right.equalTo(button.snp.left).offset(-20)
            make.top.bottom.equalToSuperview().inset(20)
        }
        
        return view
    }()
    
    // MARK:- Private properties
    var presenter: NotificationPresenterType?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        presenter = NotificationPresenter(delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Notification", comment: "")
        self.tabBarController?.cleanTitles()

        setupView()
        showLoading = true
        presenter?.fetchData( completion:{ [weak self]  in
            
            guard let weakSelf = self else { return }
            weakSelf.showLoading = false
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        if #available(iOS 18.0, *) {
            self.tabBarController?.setTabBarHidden(false, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter?.updateNotificationReadStatus()
        if #available(iOS 18.0, *) {
            if isCurrentTabRootVC {
                self.tabBarController?.setTabBarHidden(true, animated: false)
            }
        }
    }
    
    private func setupView() {

        navigationController?.navigationBar.prefersLargeTitles = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        emptyView.isHidden = true
    }
    
    private func showEmptyView(_ isShow: Bool) {
        if isShow {
            emptyView.update(hasAskPermission: presenter!.hasAskPermission)
            emptyView.isHidden = false
            tableView.setContentOffset(.zero, animated: true)
            tableView.isHidden = true
        } else {
            emptyView.isHidden = true
            tableView.isHidden = false
            if presenter!.hasAskPermission == false {
                tableView.tableHeaderView = askPermissionHeaderView
            } else {
                tableView.tableHeaderView = nil
            }
        }
        
    }
    
    @objc func tapAskPermissionBtn() {
        
        presenter!.askNotificationPermission()
    }
}

extension NotificationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return presenter?.numberOfItems() ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cellViewModel = presenter?.viewModelForIndex(indexPath.row) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: NotificationItemTableViewCell.self),
            for: indexPath
        ) as! NotificationItemTableViewCell
        cell.update(with: cellViewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let fetchCount = presenter?.numberOfItems() else { return }
        
        if indexPath.row == fetchCount - 1 {
            presenter?.loadNext(completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellViewModel = presenter?.viewModelForIndex(indexPath.row) else { return }
        switch cellViewModel.type {
        case .book:
            return
        case .externalLink:
            guard let targetURL = cellViewModel.actionId else { return }
            AppCoordinator.openWebBrowser(to: targetURL)
        default:
            break
        }
                
    }
}

extension NotificationViewController: NotificationPresenterDelegate {
    func didUpdateViewModel(viewModel: NotificationViewModel) {
        
        if viewModel.isEmpty {
            showEmptyView(true)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.showEmptyView(false)
                weakSelf.tableView.reloadData()
            }
        }
    }
    
}

extension NotificationViewController: NotificationEmptyViewDelegate {
    
    func didTapCTA(_ emptyView: NotificationEmptyView) {
        
        if presenter!.hasAskPermission {
            tabBarController?.selectedIndex = SoulverseTab.innerCosmo.rawValue
        } else {
            presenter!.askNotificationPermission()
        }
    }
    
}
