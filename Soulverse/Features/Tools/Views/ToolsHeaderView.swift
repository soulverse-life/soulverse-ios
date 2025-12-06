import SnapKit
import UIKit

class ToolsHeaderView: UIView {

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 18, weight: .bold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
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
        addSubview(titleLabel)
        addSubview(descriptionLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    // MARK: - Configuration

    func configure(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }
}
