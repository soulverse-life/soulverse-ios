//
//  SoulverseTextField.swift
//  Soulverse
//
//  Created by mingshing on 2021/12/9.
//

import UIKit

enum SoulverseTextFieldStatus: Equatable {
    case errorWithoutMessage
    case errorWithMessage(String)
    case normal
    case highlight

    var viewHeight: CGFloat {
        switch self {
        case .errorWithoutMessage, .normal, .highlight:
            return 57
        case .errorWithMessage(_):
            return 77
        }
    }
}

enum SoulverseTextFieldType {
    case password
    case account
    case general
}

protocol SoulverseTextFieldDelegate: AnyObject {

    func editingChanged(_ textField: SoulverseTextField)
    func textFieldDidEndEditing(_ textField: SoulverseTextField)
    func textFieldDidBeginEditing(_ textField: SoulverseTextField)
    func textFieldShouldReturn(_ textField: SoulverseTextField)
}

extension SoulverseTextFieldDelegate {
    func editingChanged(_ textField: SoulverseTextField) {}
    func textFieldDidEndEditing(_ textField: SoulverseTextField) {}
    func textFieldDidBeginEditing(_ textField: SoulverseTextField) {}
    func textFieldShouldReturn(_ textField: SoulverseTextField) {}
}

class SoulverseTextField: UIView {

    private var inputBorderView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.disableGray.cgColor
        view.layer.cornerRadius = 4
        return view
    }()
    
    private var inputTitleView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        
        return view
    }()
    
    private lazy var inputTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 12.0, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.font = .projectFont(ofSize: 14.0, weight: .regular)
        textField.textColor = .themeTextPrimary
        textField.autocapitalizationType = .none
        textField.delegate = self
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        textField.setLeftPaddingPoints(20)
        textField.setRightPaddingPoints(10)

        return textField
    }()
    
    private var errorMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 12.0, weight: .regular)
        label.numberOfLines = 1
        label.textColor = .primaryOrange
        return label
    }()
    
    private lazy var functionButton: UIButton = {
        let button = UIButton(type: .custom)
        
        return button
    }()
    
    weak var delegate: SoulverseTextFieldDelegate?

    var title: String
    var placeholder: String
    var text: String? {
        get {
            inputTextField.text
        }
    }
    var inputType: SoulverseTextFieldType
    var status: SoulverseTextFieldStatus = .normal

    init(title: String, placeholder: String = "", type: SoulverseTextFieldType = .general, delegate: SoulverseTextFieldDelegate? = nil) {
        self.inputType = type
        self.title = title
        self.placeholder = placeholder
        self.delegate = delegate
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 335, height: 75)))
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        self.addSubview(inputBorderView)
        inputBorderView.addSubview(inputTextField)
        
        self.addSubview(inputTitleView)
        inputTitleView.addSubview(inputTitleLabel)
        inputTitleView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(10)
        }
        
        inputTitleLabel.text = title
        inputTitleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(10)
        }
        self.addSubview(errorMessageLabel)

        
        inputBorderView.snp.makeConstraints { make in
            make.top.equalTo(inputTitleView.snp.centerY)
            make.left.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
        }
        
        inputTextField.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(inputBorderView)
            make.top.equalTo(inputBorderView.snp.top).offset(3)
        }
        self.sizeToFit()
        setupInputFieldLayout()
        updateStatus(status: .normal)
    }


    func updateStatus(status: SoulverseTextFieldStatus) {
        if status == self.status {
            return
        }
        
        switch status {
        case .normal:
            inputBorderView.layer.borderColor = UIColor.disableGray.cgColor
            inputTitleLabel.textColor = .themeTextPrimary

            errorMessageLabel.isHidden = true
            errorMessageLabel.snp.removeConstraints()
            inputBorderView.snp.remakeConstraints { make in
                make.left.bottom.centerX.equalToSuperview()
                make.top.equalTo(self.inputTitleView.snp.centerY)
                make.height.equalTo(48)
            }

        case .errorWithoutMessage:
            inputBorderView.layer.borderColor = UIColor.primaryOrange.cgColor
            inputTitleLabel.textColor = .primaryOrange

            errorMessageLabel.isHidden = true
            errorMessageLabel.snp.removeConstraints()
            inputBorderView.snp.remakeConstraints { make in
                make.left.bottom.centerX.equalToSuperview()
                make.top.equalTo(self.inputTitleView.snp.centerY)
                make.height.equalTo(48)
            }


        case .errorWithMessage(let errorMessage):
            inputBorderView.layer.borderColor = UIColor.primaryOrange.cgColor
            inputTitleLabel.textColor = .primaryOrange

            inputBorderView.snp.remakeConstraints { make in
                make.left.centerX.equalToSuperview()
                //make.bottom.equalToSuperview().offset(-13)
                make.height.equalTo(48)
                make.top.equalTo(self.inputTitleView.snp.centerY)
            }
            errorMessageLabel.text = errorMessage
            errorMessageLabel.snp.remakeConstraints { make in
                make.top.equalTo(self.inputBorderView.snp.bottom).offset(3)
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(17)
            }
            errorMessageLabel.isHidden = false

        case .highlight:
            inputBorderView.layer.borderColor = UIColor.themePrimary.cgColor
            inputTitleLabel.textColor = .themeTextPrimary

            errorMessageLabel.isHidden = true
            errorMessageLabel.snp.removeConstraints()
            inputBorderView.snp.remakeConstraints { make in
                make.left.bottom.centerX.equalToSuperview()
                make.top.equalTo(self.inputTitleView.snp.centerY)
                make.height.equalTo(48)
            }

        }
        self.status = status
        //self.sizeToFit()
    }
    
    //MARK: TextField Right View Related
    private func setupInputFieldLayout() {
        switch inputType {
        case .password:
            inputTextField.isSecureTextEntry = true
            functionButton.setImage(UIImage(named: "iconShowPassword"), for: .normal)
            functionButton.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
            functionButton.addTarget(self, action: #selector(pressFunctionButton), for: .touchUpInside)
            inputTextField.rightView = functionButton
            inputTextField.rightViewMode = .always
            inputTextField.textContentType = .newPassword
            inputTextField.autocorrectionType = .no
        case .account:
            inputTextField.keyboardType = .emailAddress
            inputTextField.textContentType = .emailAddress
            inputTextField.autocorrectionType = .no
        default:
            return
        }
        
        inputTextField.attributedPlaceholder =
        NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.disableGray])
    }
    
    @objc func pressFunctionButton(_ sender: Any) {
        
        if inputType == .password {
            
            inputTextField.isSecureTextEntry.toggle()
            if inputTextField.isSecureTextEntry {
                functionButton.setImage(UIImage(named: "iconShowPassword"), for: .normal)
            } else {
                functionButton.setImage(UIImage(named: "iconHidePassword"), for: .normal)
            }
        }
    }
    
    @objc func editingChanged() {
        
        delegate?.editingChanged(self)
    }
    
}

extension SoulverseTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        updateStatus(status: .highlight)
        delegate?.textFieldDidBeginEditing(self)
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        updateStatus(status: .normal)
        delegate?.textFieldDidEndEditing(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        //inputBorderView.layer.borderColor = KEColor.konoDisableGray()?.cgColor
        //inputTitleLabel.textColor = KEColor.articleCellBlack()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        delegate?.textFieldShouldReturn(self)
        return textField.resignFirstResponder()
    }
}
