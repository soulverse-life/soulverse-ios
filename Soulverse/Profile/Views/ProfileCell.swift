//
//  ProfileCell.swift
//  KonoSummit
//
//  Created by mingshing on 2021/11/23.
//

import Foundation
import UIKit

class ProfileCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 14, weight: .bold)
        label.textAlignment = .left
        label.textColor = UIColor.primaryWhite
        return label
    }()
    
    private var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private var actionIcon: UIImageView = {
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
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.left.equalToSuperview().inset(20)
        }
        
        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.size.equalTo(22)
            make.left.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        
        addSubview(actionIcon)
        actionIcon.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
        
    }
    
    public func update(with viewModel: ProfileCellViewModel) {
        titleLabel.text = viewModel.title
        separator.isHidden = !viewModel.isNeedSeparator
        if let actionIconName = viewModel.actionIcon {
            actionIcon.image = UIImage(named: actionIconName)
        } else {
            actionIcon.image = nil
        }
        
        if let iconName = viewModel.iconName {
            icon.image = UIImage(named: iconName)
            titleLabel.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(14)
                make.left.equalTo(icon.snp.right).offset(10)
            }
        } else {
            icon.image = nil
            titleLabel.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(14)
                make.left.equalToSuperview().inset(20)
            }
        }
    }
}
