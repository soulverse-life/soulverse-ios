//
//  PersonalInfoTableViewCell.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/19.
//

import UIKit

class PersonalInfoTableViewCell: UITableViewCell {
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        return label
    }()
    
    private var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private var leftImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private let separator = SummitSeparator(color: .backgroundBlack)
    
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
        
        addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(15)
            make.left.equalToSuperview().inset(20)
        }
        
        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.right.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        
        addSubview(leftImage)
        leftImage.snp.makeConstraints { make in
            make.size.equalTo(12)
            make.left.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        leftImage.isHidden = true
    }
    
    public func update(with viewModel: PersonalInfoCellViewModel) {
        contentLabel.text = viewModel.title
        separator.isHidden = !viewModel.isNeedSeparator
        if viewModel.isHighlight {
            contentLabel.textColor = .primaryWhite
        } else {
            contentLabel.textColor = .subGray
        }
        
        if let textColor = viewModel.textColor {
            contentLabel.textColor = textColor
        }
        
        if let registerChannel = viewModel.registerChannel {
            if registerChannel == "facebook" {
                leftImage.image = UIImage(named: "iconAccountFb")
                leftImage.isHidden = false
                contentLabel.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview().inset(15)
                    make.left.equalTo(leftImage.snp.right).offset(10)
                }
                
            } else if registerChannel == "apple" {
                leftImage.image = UIImage(named: "iconAccountApple")
                leftImage.isHidden = false
                contentLabel.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview().inset(15)
                    make.left.equalTo(leftImage.snp.right).offset(10)
                }
            } else if registerChannel == "kono" {
                leftImage.isHidden = true
                contentLabel.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview().inset(15)
                    make.left.equalToSuperview().inset(20)
                }
            }
            
        } else {
            leftImage.isHidden = true
            contentLabel.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(15)
                make.left.equalToSuperview().inset(20)
            }
        }
        
        if let iconName = viewModel.iconName {
            icon.image = UIImage(named: iconName)
        } else {
            icon.image = nil
        }
    }
}
