import SnapKit
import UIKit

class ToolsSectionHeaderView: UICollectionReusableView {

    // MARK: - UI Components

    private let titleLabel: UILabel = {
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

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(title: String) {
        titleLabel.text = title
    }
}
