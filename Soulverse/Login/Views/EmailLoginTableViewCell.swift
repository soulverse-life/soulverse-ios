//
//  EmailLoginTableViewCell.swift
//  KonoSummit
//
//  Created by mingshing on 2022/1/19.
//

import UIKit
import SwiftRichString

protocol EmailLoginTableViewCellDelegate: AnyObject {
    func inputFieldStatusDidChange(_ cell: EmailLoginTableViewCell)
    func didTapConfirmButton(_ cell: EmailLoginTableViewCell, platform: LoginPlatform)
    func didTapForgetPasswordButton(_ cell: EmailLoginTableViewCell)
    func didTapPolicyLink(_ cell: EmailLoginTableViewCell)
}

class EmailLoginTableViewCell: UITableViewCell {
    
    private lazy var accountTextField: SummitInputTextField = {
        let textField = SummitInputTextField(
            title: NSLocalizedString("login_input_title_account", comment: ""),
            placeholder: NSLocalizedString("login_input_placeholder_account", comment: ""),
            type: .account,
            delegate: self
        )
        return textField
    }()
    private lazy var passwordTextField: SummitInputTextField = {
        let textField = SummitInputTextField(
            title: NSLocalizedString("login_input_title_password", comment: ""),
            placeholder: NSLocalizedString("login_input_placeholder_password", comment: ""),
            type: .password,
            delegate: self
        )
        return textField
    }()
    private lazy var confirmPasswordTextField: SummitInputTextField = {
        let textField = SummitInputTextField(
            title: NSLocalizedString("login_input_title_confirm_password", comment: ""),
            placeholder: NSLocalizedString("login_input_placeholder_confirm_password", comment: ""),
            type: .password,
            delegate: self
        )
        return textField
    }()
    private lazy var forgetPasswordButton: UIButton = {
        let button = UIButton()
        
        button.setTitle(NSLocalizedString("login_action_forget_password", comment: ""), for: .normal)
        button.setTitleColor(UIColor.textGray, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 14, weight: .regular)
        button.addTarget(self, action: #selector(didTapForgetPassword), for: .touchUpInside)
        return button
    }()
    private lazy var registerDescriptionLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        let serviceString: String = NSLocalizedString("login_policy", comment: "")
        let confirmString: String = NSLocalizedString("login_policy_confirm", comment: "")
        let linkRange = (confirmString as NSString).range(of: serviceString)
        let baseStyle = Style {
            $0.font = UIFont.projectFont(ofSize: 14, weight: .regular)
            $0.color = UIColor.primaryBlack
        }
        let hyperlinkStyle = Style {
            $0.font = UIFont.projectFont(ofSize: 14, weight: .semibold)
            $0.color = UIColor.themeMainColor
            $0.underline = (.single, UIColor.themeMainColor)
        }
        label.attributedText = confirmString.set(style: baseStyle).add(style: hyperlinkStyle, range: linkRange)
        label.isUserInteractionEnabled = true
        let singleTap = UITapGestureRecognizer(target:self, action:#selector(didTapRegistrationLabel))
        label.addGestureRecognizer(singleTap)
        return label
    }()
    private lazy var actionButton: SoulverseButton = {
        let button = SoulverseButton(title: NSLocalizedString("login_title_register", comment: ""), image: nil, delegate: self)
        button.backgroundColor = .disableGray
        return button
    }()
    
    var displayMode: LoginViewDisplayMode = .Register {
        didSet {
            updateView()
        }
    }
    
    weak var delegate: EmailLoginTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        contentView.addSubview(accountTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(confirmPasswordTextField)
        contentView.addSubview(registerDescriptionLabel)
        contentView.addSubview(forgetPasswordButton)
        contentView.addSubview(actionButton)
            
        accountTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.contentView).offset(17)
        }
        
        passwordTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(accountTextField.snp.bottom).offset(17)
        }
        
        confirmPasswordTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(passwordTextField.snp.bottom).offset(17)
        }
        
        registerDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordTextField.snp.bottom).offset(20)
            make.left.right.equalTo(confirmPasswordTextField)
        }
        
        forgetPasswordButton.snp.makeConstraints { make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(20)
            make.right.equalToSuperview()
        }
        forgetPasswordButton.isHidden = true
        
        actionButton.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
            make.top.equalTo(registerDescriptionLabel.snp.bottom).offset(20)
        }

    }
    
    func updateView() {
        switch displayMode {
        case .Register:
            setupRegisterLayout()
        case .Login:
            setupLoginLayout()
        }
        accountTextField.updateStatus(status: .normal)
        passwordTextField.updateStatus(status: .normal)
        confirmPasswordTextField.updateStatus(status: .normal)
    }
    
    func updateErrorMsg(status: AuthResult) {

        switch status {
        case .InputDataInvalid:
            accountTextField.updateStatus(status: .errorWithoutMessage)
            passwordTextField.updateStatus(status: .errorWithMessage(NSLocalizedString("login_message_error_account", comment: "")))
        case .BadEmail:
            accountTextField.updateStatus(status: .errorWithMessage(NSLocalizedString("login_message_error_invalid_email", comment: "")))
        case .EmailNotUnique:
            accountTextField.updateStatus(status: .errorWithMessage(NSLocalizedString("login_message_error_duplicate_email", comment: "")))
        default:
            accountTextField.updateStatus(status: .normal)
            passwordTextField.updateStatus(status: .normal)
            confirmPasswordTextField.updateStatus(status: .normal)
        }
        
    }
    
    
    private func setupRegisterLayout() {
        
        confirmPasswordTextField.isHidden = false
        registerDescriptionLabel.isHidden = false
        forgetPasswordButton.isHidden = true
        
        actionButton.titleText = NSLocalizedString("login_title_register", comment: "")
        actionButton.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
            make.top.equalTo(registerDescriptionLabel.snp.bottom).offset(20)
        }
    }
    
    private func setupLoginLayout() {

        confirmPasswordTextField.isHidden = true
        registerDescriptionLabel.isHidden = true
        forgetPasswordButton.isHidden = false
        
        actionButton.titleText = NSLocalizedString("login_title_login", comment: "")
        actionButton.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
            make.top.equalTo(forgetPasswordButton.snp.bottom).offset(20)
        }
    }
    
    @objc private func didTapForgetPassword() {
        
        delegate?.didTapForgetPasswordButton(self)
    }
    
    @objc private func didTapRegistrationLabel(_ sender: UITapGestureRecognizer) {
        let serviceString: String = NSLocalizedString("login_policy", comment: "")
        let confirmString: String = NSLocalizedString("login_policy_confirm", comment: "")
        let linkRange = (confirmString as NSString).range(of: serviceString)
        if sender.didTapAttributedTextInLabel(label: registerDescriptionLabel, inRange: linkRange) {
            delegate?.didTapPolicyLink(self)
        }
    }
    
}

extension EmailLoginTableViewCell: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        if button == actionButton {

            guard let account = accountTextField.text,
                  let password = passwordTextField.text else { return }
            
            if checkInputValid() {
                delegate?.didTapConfirmButton(self, platform: .Kono(email: account, password: password))
            }
        }
    }
    func checkInputValid() -> Bool {
        
        var isValid = false
        let inputStatus = getInputStatus()
        if isInputFillout() {
            switch inputStatus {
            case .Valid:
                accountTextField.updateStatus(status: .normal)
                passwordTextField.updateStatus(status: .normal)
                confirmPasswordTextField.updateStatus(status: .normal)
                isValid = true
            case .EmailEmpty:
                accountTextField.updateStatus(status: .errorWithMessage(NSLocalizedString("login_input_error_email_empty", comment: "")))
            
            case .PasswordEmpty:
                passwordTextField.updateStatus(status: .errorWithMessage(NSLocalizedString("login_input_error_password_empty", comment: "")))
            
            case .ConfirmPasswordEmpty:
                confirmPasswordTextField.updateStatus(status: .errorWithoutMessage)
                
            case .InvalidEmail:
                accountTextField.updateStatus(status: .errorWithMessage(NSLocalizedString("login_input_error_email_format", comment: "")))
                //passwordTextField.updateStatus(status: .normal)
                
            case .DifferentPassword:
                passwordTextField.updateStatus(status: .errorWithoutMessage)
                confirmPasswordTextField.updateStatus(status: .errorWithMessage(NSLocalizedString("login_input_error_password_different", comment: "")))
            }
            
            delegate?.inputFieldStatusDidChange(self)
        }
        return isValid
    }
}

extension EmailLoginTableViewCell: SummitInputTextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: SummitInputTextField) {
        
        if checkInputValid() == false {
            actionButton.isUserInteractionEnabled = false
            actionButton.backgroundColor = .disableGray
        }
        
    }
    func editingChanged(_ textField: SummitInputTextField) {

        if isInputFillout() {
            actionButton.isUserInteractionEnabled = true
            actionButton.backgroundColor = .themeMainColor
        } else {
            actionButton.isUserInteractionEnabled = false
            actionButton.backgroundColor = .disableGray
        }
         
    }
    func getInputStatus() -> LoginViewInputCheckResult {
        guard let account = accountTextField.text else {
            return .EmailEmpty
        }
        guard let password = passwordTextField.text else {
            return .PasswordEmpty
        }
        
        if account.isEmpty {
            return .EmailEmpty
        } else if !account.isValidEmail {
            return .InvalidEmail
        } else if password.isEmpty {
            return .PasswordEmpty
        }
        
        if displayMode == .Register {
            guard let confirmPassword = confirmPasswordTextField.text else {
                return .DifferentPassword
            }
            if confirmPassword.isEmpty {
                return .ConfirmPasswordEmpty
            } else if password != confirmPassword {
                return .DifferentPassword
            }
        }
        return .Valid
    }
    
    func isInputFillout() -> Bool {
        guard let account = accountTextField.text,
              let password = passwordTextField.text else { return false }
        
        if account.isEmpty || password.isEmpty {
            return false
        }
        if displayMode == .Register {
            guard let confirmPassword = confirmPasswordTextField.text else { return false }
            if confirmPassword.isEmpty {
                return false
            }
        }
        return true
    }
}
