//
//  ForgetPasswordViewController.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/13.
//

import Foundation
import UIKit
import Toaster

class ForgetPasswordViewController: ViewController {
    
// MARK: View Related
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        
        let image = UIImage(named: "iconBack")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 24.0, weight: .bold)
        label.textColor = UIColor.primaryBlack
        label.text = "忘記密碼"
        label.textAlignment = .left
        return label
    }()
    
    private lazy var accountTextField: SummitInputTextField = {
        let textField = SummitInputTextField(title: "帳號", placeholder: "example@mail.com", type: .account, delegate: self)
        return textField
    }()
    
    private lazy var actionButton: SoulverseButton = {
        let button = SoulverseButton(title: "重設密碼", image: nil, delegate: self)
        button.backgroundColor = .disableGray
        button.isUserInteractionEnabled = false
        return button
    }()
    
//MARK: Data
    var presenter: ForgetPasswordPresenterType?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        presenter = ForgetPasswordPresenter(delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupView()
    }
    
    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.left.equalToSuperview().inset(4)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(6)
            make.left.equalToSuperview().inset(20)
        }
        
        let topSeparator = SummitSeparator(color: .primaryWhite)
        view.addSubview(topSeparator)
        topSeparator.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        
        view.addSubview(accountTextField)
        accountTextField.snp.makeConstraints { make in
            make.left.right.equalTo(topSeparator)
            make.top.equalTo(topSeparator.snp.bottom).offset(20)
        }
        
        view.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.left.right.equalTo(topSeparator)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
            make.top.equalTo(accountTextField.snp.bottom).offset(20)
        }
    }
    
    @objc private func didTapBack() {
        presenter?.didTapBackButton()
    }
}

extension ForgetPasswordViewController: ForgetPasswordPresenterDelegate {
    
    func didUpdateViewModel(viewModel: ForgetPasswordViewModel) {
        showLoading = viewModel.isLoading
    }
    
    func didFinishWithError(_ error: UserServiceError) {
        var errorMessage: String = ""
        if error == .EmailNotFound {
            errorMessage = "該使用者帳號不存在"
        } else if error == .InvalidData {
            errorMessage = "該帳號以第三方平台認證，毋須重設密碼"
        } else {
            errorMessage = "伺服器發生錯誤"
        }
        Toast(text: errorMessage, duration: Delay.short).show()
    }
    
    func didSendRecoverEmail() {
        showEmailSentConfirmAlert()
    }
    
    func dismissView() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func showEmailSentConfirmAlert() {
        
        let okAction = SummitAlertAction(title: NSLocalizedString("login_remind_password_alert_ok_action", comment: ""), style: .default) {
            self.dismissView()
        }
        SummitAlertView.shared.show(
            title: NSLocalizedString("login_remind_password_alert_title", comment: ""),
            message: NSLocalizedString("login_remind_password_alert_message", comment: ""),
            actions: [okAction]
        )
    }
}

extension ForgetPasswordViewController: SummitInputTextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: SummitInputTextField) {
        
        guard let checkResult = presenter?.checkInputValid(account: accountTextField.text) else { return }

        switch checkResult {
        case .Valid:
            actionButton.isUserInteractionEnabled = true
            actionButton.backgroundColor = .themeMainColor
            accountTextField.updateStatus(status: .normal)
            
        case .EmailEmpty:
            actionButton.isUserInteractionEnabled = false
            actionButton.backgroundColor = .disableGray
            accountTextField.updateStatus(status: .errorWithMessage("請輸入Email"))
            
        case .InvalidEmail:
            actionButton.isUserInteractionEnabled = false
            actionButton.backgroundColor = .disableGray
            accountTextField.updateStatus(status: .errorWithMessage("請輸入合法的Email"))
        }
    }
}

extension ForgetPasswordViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        
        if button == actionButton {

            guard let account = accountTextField.text else { return }
            presenter?.didTapSendButton(email: account)
        }
    }
}
