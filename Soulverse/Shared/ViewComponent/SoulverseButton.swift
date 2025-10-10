//
//  SoulverseButton.swift
//  Soulverse
//
//  Created by mingshing on 2021/12/10.
//

import Foundation
import UIKit
protocol SoulverseButtonDelegate: AnyObject {
    
    func clickSoulverseButton (_ button: SoulverseButton)
}

class SoulverseButton: UIView {
    
    weak var delegate: SoulverseButtonDelegate?
    
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.font = .projectFont(ofSize: 14.0, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    
    private let imageView: UIImageView = {
        let buttonImage = UIImageView()
        return buttonImage
    }()
    
    public var titleText: String {
        didSet {
            titleLabel.text = titleText
        }
    }
    public var buttonImage: UIImage? {
        didSet {
            imageView.image = buttonImage
        }
    }
    
    init(title: String = "", image: UIImage?, delegate: SoulverseButtonDelegate? = nil) {
        self.titleText = title
        self.buttonImage = image
        self.delegate = delegate
        super.init(frame: .zero)
        clipsToBounds = false
        self.isAccessibilityElement = true
        self.accessibilityLabel = title
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupView() {
    
        self.layer.cornerRadius = 8
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        
        if buttonImage != nil {
            addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(8)
                make.top.bottom.equalToSuperview()
            }
        }
        let singleTap = UITapGestureRecognizer(target:self, action:#selector(didTapButton))
        self.addGestureRecognizer(singleTap)
        
        titleLabel.text = titleText
        imageView.image = buttonImage
    }
    
    @objc private func didTapButton() {
        delegate?.clickSoulverseButton(self)
    }
    
}
