//
//  NotificationEmptyView.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/16.
//

import Foundation
import UIKit

protocol NotificationEmptyViewDelegate: AnyObject {
    
    func didTapCTA(_ emptyView: NotificationEmptyView)

}

class NotificationEmptyView: UIView {
    
    private var logo: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "imgNotificationEmptyState")
        return imageView
    }()
    
    private let actionTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .projectFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor.primaryWhite
        label.textAlignment = .center
        label.text = NSLocalizedString("notification_empty_title", comment: "")
        return label
    }()
    
    private let actionDescriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .projectFont(ofSize: 14)
        label.textColor = .primaryGray
        label.textAlignment = .center
        label.text = NSLocalizedString("notification_empty_browse_description", comment: "")
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .projectFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = .themeMainColor
        button.layer.cornerRadius = 4
        button.setTitle(NSLocalizedString("notification_empty_action_browse", comment: ""), for: .normal)
        button.setTitleColor(.actionButtonBlack, for: .normal)
        return button
    }()
    
    weak var delegate: NotificationEmptyViewDelegate?
    
    
    init(delegate: NotificationEmptyViewDelegate?) {
        super.init(frame: .zero)
        self.delegate = delegate
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupView() {
        
        addSubview(logo)
        logo.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(60)
            make.width.equalTo(60)
        }
        
        addSubview(actionTitleLabel)
        actionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(logo.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        addSubview(actionDescriptionLabel)
        actionDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(actionTitleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(20)
        }
        
        addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(actionDescriptionLabel.snp.bottom).offset(20)
            make.height.equalTo(44)
            make.width.equalTo(96)
            make.centerX.bottom.equalToSuperview()
        }
        actionButton.addTarget(self, action: #selector(didTapEmptyAction), for: .touchUpInside)
    }

    @objc private func didTapEmptyAction() {
        delegate?.didTapCTA(self)
    }
    
    public func update(hasAskPermission: Bool) {
        
        if hasAskPermission {
            actionDescriptionLabel.text = NSLocalizedString("notification_empty_browse_description", comment: "")
            actionButton.setTitle(NSLocalizedString("notification_empty_action_browse", comment: ""), for: .normal)
        } else {
            actionDescriptionLabel.text = NSLocalizedString("notification_empty_description", comment: "")
            actionButton.setTitle(NSLocalizedString("notification_empty_action_open", comment: ""), for: .normal)
        }
    }
}
