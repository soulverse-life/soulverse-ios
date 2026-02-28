import Hero
import SnapKit
import UIKit

class ToolsCollectionViewCell: UICollectionViewCell {

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 20
        static let iconTopLeadingInset: CGFloat = 20
        static let iconSize: CGFloat = 24
        static let titleTopOffset: CGFloat = 12
        static let labelHorizontalInset: CGFloat = 16
        static let descriptionTopOffset: CGFloat = 4
        static let lockIconSize: CGFloat = 28
        static let lockOverlayAlpha: CGFloat = 0.55
        static let borderWidth: CGFloat = 1
        static let fallbackBackgroundAlpha: CGFloat = 0.1
    }

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
        label.font = .projectFont(ofSize: 14, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 3  // Limit to 3 lines
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let lockOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(Layout.lockOverlayAlpha)
        view.isHidden = true
        view.layer.cornerRadius = Layout.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let lockIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.contentMode = .scaleAspectFit
        // White is intentional: lock icon sits on dark blur overlay regardless of theme
        imageView.tintColor = .white
        return imageView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        lockOverlayView.isHidden = true
    }

    // MARK: - Setup

    private func setupUI() {
        
        baseView.addSubview(iconImageView)
        baseView.addSubview(titleLabel)
        baseView.addSubview(descriptionLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(Layout.iconTopLeadingInset)
            make.size.equalTo(Layout.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(Layout.titleTopOffset)
            make.leading.trailing.equalToSuperview().inset(Layout.labelHorizontalInset)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.descriptionTopOffset)
            make.leading.trailing.equalToSuperview().inset(Layout.labelHorizontalInset)
        }
        
        
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = Layout.cornerRadius
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
            baseView.layer.cornerRadius = Layout.cornerRadius
            baseView.layer.borderWidth = Layout.borderWidth
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .white.withAlphaComponent(Layout.fallbackBackgroundAlpha)
            baseView.clipsToBounds = true
        }
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Add lock overlay on top of content
        if #available(iOS 26.0, *) {
            visualEffectView.contentView.addSubview(lockOverlayView)
        } else {
            baseView.addSubview(lockOverlayView)
        }

        lockOverlayView.addSubview(lockIconImageView)

        lockOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lockIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Layout.lockIconSize)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: ToolsCellViewModel) {
        // Using system symbols for now as per mock data
        iconImageView.image = UIImage(systemName: viewModel.iconName)
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description

        // Set Hero ID for the background view to enable transition
        // We use the action as a unique identifier part, or a specific ID for the spiral tool
        if viewModel.action == .selfSoothingLabyrinth {
            baseView.hero.id = "spiral_breathing_transition"
        } else {
            baseView.hero.id = nil
        }

        // Configure lock state
        lockOverlayView.isHidden = !viewModel.lockState.isLocked
    }
}
