import SnapKit
import UIKit

class ToolsCollectionViewCell: UICollectionViewCell {
    // MARK: - UI Components

    private let baseView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let visualEffectView = UIVisualEffectView()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.7)
        label.numberOfLines = 3  // Limit to 3 lines
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        
        baseView.addSubview(iconImageView)
        baseView.addSubview(titleLabel)
        baseView.addSubview(descriptionLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
            make.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = 20
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(baseView)
            contentView.addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            contentView.addSubview(baseView)
            baseView.layer.cornerRadius = 20
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .white.withAlphaComponent(0.1)
            baseView.clipsToBounds = true
        }
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: ToolsCellViewModel) {
        // Using system symbols for now as per mock data
        iconImageView.image = UIImage(systemName: viewModel.iconName)
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
    }
}
