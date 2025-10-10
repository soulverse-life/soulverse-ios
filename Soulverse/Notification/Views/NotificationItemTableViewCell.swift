//
//  NotificationTableViewCell.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/14.
//

import UIKit
import SwiftRichString
import Kingfisher

class NotificationItemTableViewCell: UITableViewCell {
    
    // MARK:- Views
    private let unreadSymbol: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 8, height: 8)))
        view.layer.cornerRadius = 4
        view.backgroundColor = .primaryOrange
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .projectFont(ofSize: 14, weight: .bold)
        label.textAlignment = .left
        label.textColor = UIColor.primaryWhite
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        label.textColor = UIColor.primaryGray
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        label.textColor = UIColor.primaryGray
        return label
    }()
    
    private let mainImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 4.0
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    
    // MARK:- Private properties
    private var viewModel: NotificationItemCellViewModel?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        contentView.addSubview(unreadSymbol)
        unreadSymbol.snp.makeConstraints { make in
            make.size.equalTo(8)
            make.top.equalToSuperview().inset(26)
            make.left.equalToSuperview().inset(12)
        }
        
        contentView.addSubview(mainImageView)
        mainImageView.snp.makeConstraints { make in
            make.size.equalTo(72)
            make.top.right.equalToSuperview().inset(20)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.left.equalToSuperview().inset(30)
            make.right.equalTo(mainImageView.snp.left).offset(-20)
        }
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(descriptionLabel.snp.bottom).offset(4)
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
    }
    
    private func getHTMLAttributedString(_ str: String) -> NSMutableAttributedString {
        let newStr = str.replacingOccurrences(of: "<br>", with: "\n")
        let fontSize: CGFloat = 14.0
        let baseStyle = Style {
            $0.font = UIFont.projectFont(ofSize: fontSize, weight: .regular)
            $0.color = UIColor.primaryGray
            $0.lineSpacing = 2
        }
                
        let italicStyle = Style {
            $0.font = UIFont.italicSystemFont(ofSize: fontSize)
        }
        
        let boldStyle = Style {
            $0.font = UIFont.boldSystemFont(ofSize: fontSize)
        }
        
        // A group container includes all the style defined.
        let groupStyle = StyleXML.init(base: baseStyle, ["b" : boldStyle, "i": italicStyle])
        
        return newStr.set(style: groupStyle)
    }
    
    public func update(with viewModel: NotificationItemCellViewModel) {
        
        self.viewModel = viewModel
        
        if viewModel.hasRead {
            unreadSymbol.isHidden = true
            self.backgroundColor = .backgroundBlack
        } else {
            unreadSymbol.isHidden = false
            self.backgroundColor = .subBackgroundBlack
        }
        
        titleLabel.text = viewModel.title
        titleLabel.sizeToFit()
        
        descriptionLabel.attributedText = getHTMLAttributedString(viewModel.description)
        descriptionLabel.sizeToFit()
        
        mainImageView.kf.setImage(with: URL(string: viewModel.mainImageURL))
        
        timeLabel.text = viewModel.createTimeString
    }
}
