//
//  MoodEntriesSection.swift
//  Soulverse
//
//  Container view for horizontal scroll of mood entry cards.
//

import SnapKit
import UIKit

protocol MoodEntriesSectionDelegate: AnyObject {
    func moodEntriesSectionDidTapDraw(_ section: MoodEntriesSection, checkinId: String?)
    func moodEntriesSectionDidRequestMore(_ section: MoodEntriesSection)
}

class MoodEntriesSection: UIView {

    // MARK: - Properties

    weak var delegate: MoodEntriesSectionDelegate?

    private var entries: [MoodEntryCardCellViewModel] = []
    private var isRequestingMore = false

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(
            width: InnerCosmoLayout.moodEntryCardWidth,
            height: InnerCosmoLayout.moodEntryCardHeight
        )
        layout.minimumLineSpacing = InnerCosmoLayout.moodEntryCardSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: InnerCosmoLayout.horizontalPadding,
            bottom: 0,
            right: InnerCosmoLayout.horizontalPadding
        )

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(MoodEntryCardCell.self, forCellWithReuseIdentifier: MoodEntryCardCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        return cv
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
        addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(InnerCosmoLayout.moodEntryCardHeight)
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Public Methods

    func configure(with entries: [MoodEntryCardCellViewModel]) {
        isRequestingMore = false
        self.entries = entries
        collectionView.reloadData()
    }

    func appendEntries(_ newEntries: [MoodEntryCardCellViewModel]) {
        guard !newEntries.isEmpty else {
            isRequestingMore = false
            return
        }
        let startIndex = entries.count
        entries.append(contentsOf: newEntries)
        let indexPaths = (startIndex..<entries.count).map { IndexPath(item: $0, section: 0) }
        collectionView.insertItems(at: indexPaths)
        isRequestingMore = false
    }
}

// MARK: - UICollectionViewDataSource

extension MoodEntriesSection: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return entries.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MoodEntryCardCell.reuseIdentifier,
            for: indexPath
        ) as? MoodEntryCardCell else {
            return UICollectionViewCell()
        }

        let entry = entries[indexPath.item]
        cell.configure(with: entry)
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MoodEntriesSection: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // No action for now - future: navigate to detail view
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let threshold = 3
        if entries.count > threshold, indexPath.item >= entries.count - threshold, !isRequestingMore {
            isRequestingMore = true
            delegate?.moodEntriesSectionDidRequestMore(self)
        }
    }
}

// MARK: - MoodEntryCardCellDelegate

extension MoodEntriesSection: MoodEntryCardCellDelegate {

    func moodEntryCardDidTapDraw(_ cell: MoodEntryCardCell, checkinId: String?) {
        delegate?.moodEntriesSectionDidTapDraw(self, checkinId: checkinId)
    }
}
