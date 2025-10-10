//
//  ChangePasswordViewController.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/21.
//

import UIKit
import Toaster

class ChangePasswordViewController: ViewController {
    
    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .backgroundBlack
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .none
        table.bounces = false
        table.register(
            ChangePasswordTableViewCell.self,
            forCellReuseIdentifier: String(describing: ChangePasswordTableViewCell.self)
        )
        table.delegate = self
        table.dataSource = self
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ViewComponentConstants.miniBarHeight - 20.0, right: 0)
        table.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return table
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("change_password_action_button_title", comment: ""), for: .normal)
        button.setTitleColor(.primaryWhite, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 14.0, weight: .bold)
        button.backgroundColor = .subGray
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(changePassword), for: .touchUpInside)
        button.isUserInteractionEnabled = false
        return button
    }()
    

    var presenter: ChangePasswordPresenterType?
    
    init() {
        
        super.init(nibName: nil, bundle: nil)

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
        presenter = ChangePasswordPresenter(delegate: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func setupView() {
        
        title = NSLocalizedString("personal_info_row_change_password", comment: "")
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        configFooterView()
    }
    
    private func configFooterView() {
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: DeviceConstants.width, height: 58))
        footerView.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
        self.tableView.tableFooterView = footerView
    }
    
    @objc func changePassword() {
        
        presenter?.changePassword()
        
    }
    
}

extension ChangePasswordViewController: ChangePasswordPresenterDelegate {
    func didChangePassword() {
        
        Toast(text: NSLocalizedString("change_password_success", comment: ""), duration: Delay.short).show()
        DispatchQueue.main.asyncAfter(deadline: .now() + Delay.short) {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    func didUpdateViewModel(viewModel: ChangePasswordViewModel) {
        
        self.tableView.reloadData()
    }
    
    func updateActionStatus(isEnable: Bool) {
        if isEnable {
            actionButton.isUserInteractionEnabled = true
            actionButton.backgroundColor = .themeMainColor
            
        } else {
            actionButton.isUserInteractionEnabled = false
            actionButton.backgroundColor = .subGray
        }
    }
    
}

extension ChangePasswordViewController: UITableViewDataSource, UITableViewDelegate {
    
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
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        guard let errorMessage = presenter?.errorMsgForSection(section) else { return nil }
        
        let messageLabel = UILabel()
        messageLabel.numberOfLines = 1
        messageLabel.font = .projectFont(ofSize: 12, weight: .regular)
        messageLabel.textAlignment = .left
        messageLabel.textColor = .errorRed
        messageLabel.text = errorMessage
        
        let errorMessageView = UIView()
        errorMessageView.backgroundColor = .clear
        errorMessageView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(10)
        }
        return errorMessageView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cellViewModel = presenter?.viewModelForIndex(indexPath: indexPath) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: ChangePasswordTableViewCell.self),
            for: indexPath
        ) as! ChangePasswordTableViewCell
        cell.update(with: cellViewModel, delegate: self)
        return cell
    }
    
}

extension ChangePasswordViewController: ChangePasswordTableViewCellDelegate {
    
    func cellTextFieldTextChanged(_ viewModel: ChangePasswordCellViewModel) {
     
        presenter?.inputTextChangedWithCell(viewModel)
    }
    
}
