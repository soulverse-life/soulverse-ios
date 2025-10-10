//
//  LoginViewController.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/6.
//

import Foundation
import UIKit
import IQKeyboardManagerSwift
import SwiftRichString
import Toaster
import Firebase

class LoginViewController: ViewController {

// MARK: View Related
    
    private lazy var loginTableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .white
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .none
        table.bounces = false
        table.clipsToBounds = false
        table.register(
            ThirdPartyLoginTableViewCell.self,
            forCellReuseIdentifier: String(describing: ThirdPartyLoginTableViewCell.self)
        )
        
        table.register(
            EmailLoginTableViewCell.self,
            forCellReuseIdentifier: String(describing: EmailLoginTableViewCell.self)
        )
        
        table.delegate = self
        table.dataSource = self

        return table
    }()
    private lazy var dismissButton: UIButton = {
        let button = UIButton()
        
        let image = UIImage(named: "naviconClose")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        return button
    }()
    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 14.0, weight: .regular)
        label.textColor = UIColor.primaryBlack
        label.text = NSLocalizedString("login_switch_or", comment: "")
        label.textAlignment = .right
        return label
    }()
    private lazy var switchButton: UIButton = {
        let button = UIButton()
        
        button.setTitle(NSLocalizedString("login_switch_register", comment: ""), for: .normal)
        button.setTitleColor(UIColor.themeMainColor, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 14, weight: .semibold)
        button.addTarget(self, action: #selector(didTapSwitch), for: .touchUpInside)
        return button
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 24.0, weight: .bold)
        label.textColor = UIColor.primaryBlack
        label.text = NSLocalizedString("login_title_register", comment: "")
        label.textAlignment = .left
        return label
    }()

    private lazy var emailTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 16.0, weight: .semibold)
        label.textColor = UIColor.subBlack
        label.text = NSLocalizedString("login_action_email_register", comment: "")
        label.textAlignment = .left
        return label
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton()
        
        button.setTitle(NSLocalizedString("login_action_skip", comment: ""), for: .normal)
        button.setTitleColor(UIColor.textGray, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 14, weight: .regular)
        button.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
        return button
    }()
    
//MARK: Data
    private var tracker: CoreTracker?
    private var sourcePage: AppLocation
    private var loginSuccessBlock: (()->())?
    var presenter: LoginViewPresenterType?
    
    init(sourcePage: AppLocation, success:(()->())?, tracker: CoreTracker? = SummitTracker.shared) {
        self.sourcePage = sourcePage
        self.tracker = tracker
        self.loginSuccessBlock = success
        super.init(nibName: nil, bundle: nil)
        presenter = LoginViewPresenter(.Register, sourcePage: sourcePage, delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupView()
        tracker?.track(AccountEvent.viewRegisterPage(source: sourcePage))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.keyboardDistance = 60
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.left.equalToSuperview().inset(4)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(5)
        }
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dismissButton.snp.bottom).offset(6)
            make.left.equalToSuperview().inset(20)
        }
        
        view.addSubview(switchButton)
        switchButton.snp.makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp.bottom)
            make.right.equalToSuperview().offset(-20)
        }
        
        view.addSubview(switchLabel)
        switchLabel.snp.makeConstraints { make in
            make.right.equalTo(switchButton.snp.left).offset(-5)
            make.centerY.equalTo(switchButton)
        }
        
        let topSeparator = SummitSeparator(color: .primaryWhite)
        view.addSubview(topSeparator)
        topSeparator.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        view.addSubview(loginTableView)
        loginTableView.snp.makeConstraints { make in
            make.top.equalTo(topSeparator.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
        configLoginTableFooterView()
        
        let isNeedForceLogin = sourcePage == .BackgroundProcess
        dismissButton.isHidden = isNeedForceLogin
        skipButton.isHidden = isNeedForceLogin


    }
    
    private func configLoginTableFooterView() {
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: loginTableView.bounds.width, height: 88))
        footerView.addSubview(skipButton)
        skipButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        loginTableView.tableFooterView = footerView
    }
    
    @objc private func didTapBack() {
        presenter?.didTapBackButton()
    }
    
    @objc private func didTapSkip() {
        presenter?.didTapSkipButton()
    }
    
    @objc private func didTapSwitch() {
        presenter?.didTapSwitchButton()
    }
    
}

extension LoginViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return presenter?.numberOfSections() ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.numberOfItems(of: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let viewSection = presenter?.viewModel.sectionList[section] else { return 0 }
        
        if viewSection == .Email {
            return 45
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let viewSection = presenter?.viewModel.sectionList[section] else { return 0 }
        
        if viewSection == .ThirdParty {
            return 20
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let viewSection = presenter?.viewModel.sectionList[section] else { return nil }
        if viewSection == .Email {
            let headerView = UIView()
            
            headerView.addSubview(emailTitleLabel)
            
            emailTitleLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(20)
            }
            return headerView
        }
        return nil
    }
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        let separator = SummitSeparator(color: .primaryWhite)
        footerView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.bottom.equalToSuperview()
        }
        return footerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        guard let loginPlatform = presenter?.loginPlatformForIndex(section: indexPath.section, row: indexPath.row),
              let viewSection = presenter?.viewModel.sectionList[indexPath.section] else { return UITableViewCell() }
        
        if viewSection == .ThirdParty {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: ThirdPartyLoginTableViewCell.self),
                for: indexPath
            ) as! ThirdPartyLoginTableViewCell
            cell.delegate = self
            cell.update(platform: loginPlatform)
            return cell
        } else {
            
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: EmailLoginTableViewCell.self),
                for: indexPath
            ) as! EmailLoginTableViewCell
            
            cell.delegate = self
            return cell
        }
    }
}


extension LoginViewController: LoginViewPresenterDelegate {

    func didChangeDisplayMode(_ viewModel: LoginViewModel) {
        guard let cell = loginTableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? EmailLoginTableViewCell else { return }
        cell.displayMode = viewModel.displayMode
        loginTableView.reloadData()
        
        switch viewModel.displayMode {
        case .Register:
            setupRegisterLayout()
        case .Login:
            setupLoginLayout()
        }
    }
    
    func startAuthProcess() {
        showLoading = true
    }
    
    func didFinishedAuthProcess(_ result: AuthResult) {
        showLoading = false
        switch result {
        case .AuthLoginSuccess:
            Toast(text: NSLocalizedString("login_message_success_login", comment: ""), duration: Delay.short).show()
            DispatchQueue.main.asyncAfter(deadline: .now() + Delay.short) {
                self.dismissView()
                self.loginSuccessBlock?()
            }
            
        case .AuthSignupSuccess:
            Toast(text: NSLocalizedString("login_message_success_register", comment: ""), duration: Delay.short).show()
            DispatchQueue.main.asyncAfter(deadline: .now() + Delay.short) {
                self.dismissView()
                self.loginSuccessBlock?()
            }
            
        case .InputDataInvalid, .BadEmail, .EmailNotUnique:
            guard let cell = loginTableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? EmailLoginTableViewCell else { return }
            cell.updateErrorMsg(status: result)
            loginTableView.reloadData()
            
        case .ThirdPartyServiceError(_), .ServerError:
            Toast(text: NSLocalizedString("message_error_server", comment: ""), duration: Delay.short).show()
        
        case .NetworkError:
            Toast(text: NSLocalizedString("message_error_network", comment: ""), duration: Delay.short).show()
            
        case .UserCancel:
            print("使用者自行終止")
            
        case .UnknownError:
            Toast(text: NSLocalizedString("message_error_unknown", comment: ""), duration: Delay.short).show()
        }
         
    }
    
    func openPolicy() {
        let vc = WebViewController(title: NSLocalizedString("profile_policy", comment: ""), targetUrl: HostAppContants.policyUrl)
        show(vc, sender: self)
    }
    
    func openForgetPassword() {
        let vc = ForgetPasswordViewController()
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupRegisterLayout() {
        titleLabel.text = NSLocalizedString("login_title_register", comment: "")
        switchButton.setTitle(NSLocalizedString("login_switch_register", comment: ""), for: .normal)
        emailTitleLabel.text = NSLocalizedString("login_action_email_register", comment: "")
    }
    
    private func setupLoginLayout() {
        titleLabel.text = NSLocalizedString("login_title_login", comment: "")
        switchButton.setTitle(NSLocalizedString("login_switch_login", comment: ""), for: .normal)
        emailTitleLabel.text = NSLocalizedString("login_action_email_login", comment: "")
    }
}

extension LoginViewController: ThirdPartyLoginTableViewCellDelegate {
    func didTapActionButton(_ cell: ThirdPartyLoginTableViewCell) {
        presenter?.didTapLoginAction(platform: cell.actionPlatform)
    }
}

extension LoginViewController: EmailLoginTableViewCellDelegate {
    
    func inputFieldStatusDidChange(_ cell: EmailLoginTableViewCell) {
        loginTableView.reloadData()
    }
    
    func didTapConfirmButton(_ cell: EmailLoginTableViewCell, platform: LoginPlatform) {
        presenter?.didTapLoginAction(platform: platform)
    }
    
    func didTapForgetPasswordButton(_ cell: EmailLoginTableViewCell) {
        presenter?.didTapForgetPassword()
    }
    
    func didTapPolicyLink(_ cell: EmailLoginTableViewCell) {
        presenter?.didTapUserPolicy()
    }
    
}
