import SnapKit
import UIKit

class ToolsHeaderView: UICollectionReusableView {

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.7)
        return label
    }()

    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 20, weight: .semibold)
        label.textColor = .white
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
        addSubview(subtitleLabel)
        addSubview(sectionTitleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
        }

        sectionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    // MARK: - Configuration

    func configure(title: String, subtitle: String, sectionTitle: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        sectionTitleLabel.text = sectionTitle
    }
}
