//
//  TimeRangeToggleView.swift
//

import UIKit
import SnapKit

protocol TimeRangeToggleViewDelegate: AnyObject {
    func timeRangeToggleView(_ view: TimeRangeToggleView, didSelect range: TimeRange)
}

class TimeRangeToggleView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let tagsHeight: CGFloat = 48
    }

    // MARK: - Properties

    weak var delegate: TimeRangeToggleViewDelegate?
    private(set) var selectedRange: TimeRange = .last7Days

    // MARK: - Subviews

    private lazy var tagsView: SoulverseTagsView = {
        let view = SoulverseTagsView.create(horizontalSpacing: 8, verticalSpacing: 8, itemHeight: Layout.tagsHeight)
        view.selectionMode = .single
        view.delegate = self
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        addSubview(tagsView)

        tagsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.height.equalTo(Layout.tagsHeight)
        }

        tagsView.setItems(makeItems())
    }

    // MARK: - Helpers

    private func makeItems() -> [SoulverseTagsItemData] {
        return [
            SoulverseTagsItemData(
                title: TimeRange.last7Days.displayTitle,
                isSelected: selectedRange == .last7Days,
                tag: "last7Days"
            ),
            SoulverseTagsItemData(
                title: TimeRange.all.displayTitle,
                isSelected: selectedRange == .all,
                tag: "all"
            )
        ]
    }

    private func timeRange(from tag: String?) -> TimeRange? {
        switch tag {
        case "last7Days": return .last7Days
        case "all": return .all
        default: return nil
        }
    }
}

// MARK: - SoulverseTagsViewDelegate

extension TimeRangeToggleView: SoulverseTagsViewDelegate {
    func soulverseTagsView(_ view: SoulverseTagsView, didUpdateSelectedItems items: [SoulverseTagsItemData]) {
        // Enforce always-one-selected: if nothing is selected, restore previous selection
        guard let selectedItem = items.first,
              let range = timeRange(from: selectedItem.tag) else {
            tagsView.setItems(makeItems())
            return
        }

        selectedRange = range
        delegate?.timeRangeToggleView(self, didSelect: range)
    }
}
