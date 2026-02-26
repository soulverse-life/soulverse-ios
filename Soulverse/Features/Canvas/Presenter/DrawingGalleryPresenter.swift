//
//  DrawingGalleryPresenter.swift
//  Soulverse
//

import Foundation

// MARK: - Delegate Protocol

protocol DrawingGalleryPresenterDelegate: AnyObject {
    func didUpdate(viewModel: DrawingGalleryViewModel)
}

// MARK: - Presenter Protocol

protocol DrawingGalleryPresenterType: AnyObject {
    var delegate: DrawingGalleryPresenterDelegate? { get set }
    func fetchDrawings()
}

// MARK: - Implementation

final class DrawingGalleryPresenter: DrawingGalleryPresenterType {

    weak var delegate: DrawingGalleryPresenterDelegate?

    private static let fetchDaysRange: Int = 90

    private static let dayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private var isFetching = false

    func fetchDrawings() {
        guard !isFetching else { return }
        guard let uid = User.shared.userId else {
            delegate?.didUpdate(viewModel: DrawingGalleryViewModel())
            return
        }

        isFetching = true
        delegate?.didUpdate(viewModel: DrawingGalleryViewModel(isLoading: true))

        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -Self.fetchDaysRange,
            to: Date()
        ) ?? Date()

        FirestoreDrawingService.fetchDrawings(uid: uid, from: startDate) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetching = false

                switch result {
                case .success(let drawings):
                    let sections = self.groupByDay(drawings)
                    self.delegate?.didUpdate(
                        viewModel: DrawingGalleryViewModel(isLoading: false, sections: sections)
                    )
                case .failure(let error):
                    self.delegate?.didUpdate(
                        viewModel: DrawingGalleryViewModel(
                            isLoading: false,
                            errorMessage: error.localizedDescription
                        )
                    )
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func groupByDay(_ drawings: [DrawingModel]) -> [DrawingGallerySectionViewModel] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: drawings) { drawing -> Date in
            guard let createdAt = drawing.createdAt else { return Date.distantPast }
            return calendar.startOfDay(for: createdAt)
        }

        return grouped.keys
            .sorted(by: >)
            .map { dayDate in
                let title = dayDate == Date.distantPast
                    ? NSLocalizedString("gallery_unknown_date", comment: "Unknown date")
                    : Self.dayDateFormatter.string(from: dayDate)
                let dayDrawings = grouped[dayDate] ?? []
                return DrawingGallerySectionViewModel(title: title, drawings: dayDrawings)
            }
    }
}
