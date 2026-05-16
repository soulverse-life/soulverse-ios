//
//  RecentResultCardListView.swift
//  Soulverse
//
//  Vertical stack of result cards. Tapping a card invokes onSelect.
//

import UIKit
import SnapKit

final class RecentResultCardListView: UIView {

    private let stack = UIStackView()
    private var lastRenderedResults: [RecentResultCardModel]?
    var onSelect: ((RecentResultCardModel) -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        stack.axis = .vertical
        stack.spacing = 10
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(results: [RecentResultCardModel]) {
        guard results != lastRenderedResults else { return }
        lastRenderedResults = results

        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for result in results {
            let card = RecentResultCardView()
            card.configure(model: result)
            card.onTap = { [weak self] in self?.onSelect?(result) }
            stack.addArrangedSubview(card)
        }
        isHidden = results.isEmpty
    }
}
