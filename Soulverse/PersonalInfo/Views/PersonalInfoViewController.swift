//
//  PersonalInfoViewController.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/19.
//

import UIKit

class PersonalInfoViewController: ViewController {
    
    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .backgroundBlack
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .none
        
        table.register(
            PersonalInfoTableViewCell.self,
            forCellReuseIdentifier: String(describing: PersonalInfoTableViewCell.self)
        )
        table.delegate = self
        table.dataSource = self
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ViewComponentConstants.miniBarHeight - 20.0, right: 0)
        table.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return table
    }()

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var headerView: UIView = { [weak self] in

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: DeviceConstants.width, height: 140))
        headerView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.size.equalTo(100)
        }
        return headerView
    }()
    
    private lazy var infoLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = .projectFont(ofSize: 12, weight: .regular)
        label.textColor = .subGray
        label.textAlignment = .center
        return label
    }()
    
    var user: User?
    var presenter: PersonalInfoPresenterType?
    
    init(user: User = User.instance) {
        
        super.init(nibName: nil, bundle: nil)
        self.user = user
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        showLoading = true
        presenter = PersonalInfoPresenter(user: user!, delegate: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func setupView() {
    
        self.title = NSLocalizedString("profile_info", comment: "")
        view.addSubview(tableView)
        view.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(infoLabel.snp.top)
        }
        tableView.tableHeaderView = headerView
    }
}

extension PersonalInfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return presenter?.numberOfSections() ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.numberOfItems(of: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.font = .projectFont(ofSize: 14, weight: .regular)
        titleLabel.textAlignment = .left
        titleLabel.textColor = UIColor.primaryGray
        titleLabel.text = presenter?.titleForSection(section)
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(10)
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cellViewModel = presenter?.viewModelForIndex(indexPath: indexPath) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: PersonalInfoTableViewCell.self),
            for: indexPath
        ) as! PersonalInfoTableViewCell
        cell.update(with: cellViewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        presenter?.didSelectForIndexPath(indexPath: indexPath)
    }
    
}

extension PersonalInfoViewController: PersonalInfoPresenterDelegate {
    
    func didUpdateViewModel(viewModel: PersonalInfoViewModel) {
        
        showLoading = false
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.infoLabel.text = String(format: NSLocalizedString("personal_info_support", comment: ""), Utility.getAppVersion(), weakSelf.user?.userId ?? "")
            weakSelf.avatarImageView.kf.setImage(with: URL(string: viewModel.avatarImageURL))
            weakSelf.tableView.reloadData()
        }
    }
    
    func openChangePassword() {
        let vc = ChangePasswordViewController()
        show(vc, sender: self)
    }
    
    func deleteAccount() {
        //MARK: handle the delete account flow
    }
}
