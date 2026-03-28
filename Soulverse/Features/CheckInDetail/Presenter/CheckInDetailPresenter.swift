//
//  CheckInDetailPresenter.swift
//  Soulverse
//

import Foundation

final class CheckInDetailPresenter: CheckInDetailPresenterType {

    // MARK: - Properties

    weak var delegate: CheckInDetailPresenterDelegate?

    private let checkIns: [MoodCheckInModel]
    private var currentIndex: Int
    private let user: UserProtocol
    private let drawingService: DrawingServiceProtocol
    private let journalService: JournalServiceProtocol

    // MARK: - Initialization

    init(checkIns: [MoodCheckInModel],
         initialIndex: Int = 0,
         user: UserProtocol = User.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared,
         journalService: JournalServiceProtocol = FirestoreJournalService.shared) {
        self.checkIns = checkIns
        self.currentIndex = min(initialIndex, max(checkIns.count - 1, 0))
        self.user = user
        self.drawingService = drawingService
        self.journalService = journalService
    }

    // MARK: - Navigation

    func goToNext() {
        guard currentIndex < checkIns.count - 1 else { return }
        currentIndex += 1
        loadCurrentCheckIn()
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        loadCurrentCheckIn()
    }

    // MARK: - Data Loading

    func loadCurrentCheckIn() {
        guard currentIndex < checkIns.count else { return }
        let checkIn = checkIns[currentIndex]

        guard let uid = user.userId else {
            let viewModel = buildViewModel(checkIn: checkIn, drawing: nil, journal: nil)
            delegate?.didUpdateViewModel(viewModel)
            return
        }

        let group = DispatchGroup()
        var fetchedDrawing: DrawingModel?
        var fetchedJournal: JournalModel?

        // Fetch drawing if linked
        if let checkinId = checkIn.id {
            group.enter()
            drawingService.fetchDrawings(uid: uid, checkinId: checkinId) { result in
                if case .success(let drawings) = result {
                    fetchedDrawing = drawings.first
                }
                group.leave()
            }
        }

        // Fetch journal if linked
        if let journalId = checkIn.journalId {
            group.enter()
            journalService.fetchJournal(uid: uid, journalId: journalId) { result in
                if case .success(let journal) = result {
                    fetchedJournal = journal
                }
                group.leave()
            }
        } else if let checkinId = checkIn.id {
            // Fallback: query by checkinId
            group.enter()
            journalService.fetchJournal(uid: uid, checkinId: checkinId) { result in
                if case .success(let journal) = result {
                    fetchedJournal = journal
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let viewModel = self.buildViewModel(checkIn: checkIn, drawing: fetchedDrawing, journal: fetchedJournal)
            self.delegate?.didUpdateViewModel(viewModel)
        }
    }

    // MARK: - ViewModel Construction

    private func buildViewModel(
        checkIn: MoodCheckInModel,
        drawing: DrawingModel?,
        journal: JournalModel?
    ) -> CheckInDetailViewModel {
        let emotion = RecordedEmotion(rawValue: checkIn.emotion)
        let topic = Topic(rawValue: checkIn.topic)
        let intensityLevel = ColorIntensityConstants.level(forAlpha: checkIn.colorIntensity)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateText = checkIn.createdAt.map { dateFormatter.string(from: $0) } ?? ""

        return CheckInDetailViewModel(
            dateText: dateText,
            emotionName: emotion?.displayName ?? checkIn.emotion,
            colorHex: checkIn.colorHex,
            colorIntensity: checkIn.colorIntensity,
            intensityLevel: intensityLevel,
            topicLabel: topic?.localizedTitle ?? checkIn.topic,
            topicRawValue: checkIn.topic,
            currentIndex: currentIndex,
            totalCount: checkIns.count,
            drawingImageURL: drawing?.imageURL,
            reflectionPrompt: checkIn.reflectionPrompt,
            reflectionText: checkIn.reflection,
            journalTitle: journal?.title,
            journalContent: journal?.content,
            checkinId: checkIn.id
        )
    }
}
