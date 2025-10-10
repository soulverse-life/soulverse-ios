//
//  ChangePasswordTableViewCell.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/21.
//

import UIKit

protocol ChangePasswordTableViewCellDelegate: AnyObject {
    
    //func cellTextFieldDidEndEditing(_ viewModel: ChangePasswordCellViewModel, text: String)
    func cellTextFieldTextChanged(_ viewModel: ChangePasswordCellViewModel)
    //func cellTextFieldDidBeginEditing(_ viewModel: ChangePasswordCellViewModel, text: String)
    //func textFieldShouldReturn(_ viewModel: ChangePasswordCellViewModel, text: String)
}


class ChangePasswordTableViewCell: UITableViewCell {
    
    private lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.font = .projectFont(ofSize: 14.0, weight: .regular)
        textField.textColor = .primaryWhite
        textField.autocapitalizationType = .none
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        textField.setLeftPaddingPoints(20)
        textField.setRightPaddingPoints(10)
        
        textField.isSecureTextEntry = true
        textField.rightView = functionButton
        textField.rightViewMode = .always
        textField.textContentType = .newPassword
        textField.autocorrectionType = .no
        
        return textField
    }()
    
    private lazy var functionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "iconShowPassword"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        button.addTarget(self, action: #selector(pressFunctionButton), for: .touchUpInside)
        return button
    }()
    
    private let separator = SummitSeparator(color: .backgroundBlack)
    private var viewModel: ChangePasswordCellViewModel?
    private weak var delegate: ChangePasswordTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .groupAreaBackgroundBlack
        selectionStyle = .none
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        self.contentView.addSubview(inputTextField)
        inputTextField.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    @objc func pressFunctionButton(_ sender: Any) {
   
        inputTextField.isSecureTextEntry.toggle()
        viewModel?.isSecureEnable = inputTextField.isSecureTextEntry
        if inputTextField.isSecureTextEntry {
            functionButton.setImage(UIImage(named: "iconShowPassword"), for: .normal)
        } else {
            functionButton.setImage(UIImage(named: "iconHidePassword"), for: .normal)
        }
    }
    
    
    public func update(with viewModel: ChangePasswordCellViewModel, delegate: ChangePasswordTableViewCellDelegate? = nil) {
        
        self.viewModel = viewModel
        self.delegate = delegate
        inputTextField.attributedPlaceholder =
        NSAttributedString(string: viewModel.placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.subGray])
        
        inputTextField.text = viewModel.text
        inputTextField.isSecureTextEntry = viewModel.isSecureEnable
        if inputTextField.isSecureTextEntry {
            functionButton.setImage(UIImage(named: "iconShowPassword"), for: .normal)
        } else {
            functionButton.setImage(UIImage(named: "iconHidePassword"), for: .normal)
        }
        separator.isHidden = !viewModel.needSeparator
    }
    
    @objc func editingChanged() {
        
        if viewModel != nil {
            viewModel?.text = inputTextField.text
            delegate?.cellTextFieldTextChanged(viewModel!)
        }
        
    }
}
