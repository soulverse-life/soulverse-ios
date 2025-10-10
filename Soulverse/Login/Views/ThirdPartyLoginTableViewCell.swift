//
//  ThirdPartyLoginTableViewCell.swift
//  KonoSummit
//
//  Created by mingshing on 2022/1/19.
//

import UIKit

protocol ThirdPartyLoginTableViewCellDelegate: AnyObject {
    
    func didTapActionButton(_ cell: ThirdPartyLoginTableViewCell)
}


class ThirdPartyLoginTableViewCell: UITableViewCell {

    private lazy var appleButton: SoulverseButton = {
        let button = SoulverseButton(title: NSLocalizedString("login_action_apple", comment: ""), image: UIImage(named: "appleLogo"), delegate: self)
        button.backgroundColor = .black
        return button
    }()
    
    var actionPlatform: LoginPlatform!
    weak var delegate: ThirdPartyLoginTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        for subView in contentView.subviews {
            subView.removeFromSuperview()
        }

        switch actionPlatform {
        case .Apple:
            contentView.addSubview(appleButton)
            appleButton.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(5)
                make.left.right.equalToSuperview()
                make.height.equalTo(44)
            }
        default:
            break
        }
        contentView.clipsToBounds = false
    }
    
    func update(platform: LoginPlatform) {
        self.actionPlatform = platform
        setupView()
    }
}

extension ThirdPartyLoginTableViewCell: SoulverseButtonDelegate {
    
    func clickSoulverseButton(_ button: SoulverseButton) {
        delegate?.didTapActionButton(self)
    }
    
}
