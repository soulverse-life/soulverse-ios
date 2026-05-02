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

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    // MARK: - Initialization

    init(checkIns: [MoodCheckInModel],
         initialIndex: Int = 0,
         user: UserProtocol = User.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared,
         journalService: JournalServiceProtocol = FirestoreJournalService.shared) {
        let persistedCheckIns = checkIns.filter { $0.id != nil }
        self.checkIns = persistedCheckIns
        self.currentIndex = min(initialIndex, max(persistedCheckIns.count - 1, 0))
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
        guard let checkinId = checkIn.id else { return }

        // Phase 1: Show mandatory data immediately (planet, emotion, tags)
        let immediateViewModel = buildViewModel(checkIn: checkIn, drawing: nil, journal: nil, isLoadingContent: true)
        delegate?.didUpdateViewModel(immediateViewModel)

        // Phase 2: Fetch drawing + journal async, then update sections
        guard let uid = user.userId else { return }

        let capturedIndex = currentIndex
        let group = DispatchGroup()
        var fetchedDrawing: DrawingModel?
        var fetchedJournal: JournalModel?

        group.enter()
        drawingService.fetchDrawings(uid: uid, checkinId: checkinId) { result in
            if case .success(let drawings) = result {
                fetchedDrawing = drawings.first
            }
            group.leave()
        }

        if let journalId = checkIn.journalId {
            group.enter()
            journalService.fetchJournal(uid: uid, journalId: journalId) { result in
                if case .success(let journal) = result {
                    fetchedJournal = journal
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self, self.currentIndex == capturedIndex else { return }
            let viewModel = self.buildViewModel(checkIn: checkIn, drawing: fetchedDrawing, journal: fetchedJournal, isLoadingContent: false)
            self.delegate?.didUpdateViewModel(viewModel)
        }
    }

    // MARK: - ViewModel Construction

    private func buildViewModel(
        checkIn: MoodCheckInModel,
        drawing: DrawingModel?,
        journal: JournalModel?,
        isLoadingContent: Bool
    ) -> CheckInDetailViewModel {
        let emotion = RecordedEmotion(rawValue: checkIn.emotion)
        let topic = Topic(rawValue: checkIn.topic)
        let intensityLevel = ColorIntensityConstants.level(forAlpha: checkIn.colorIntensity)
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
            isLoadingContent: isLoadingContent,
            hasLinkedDrawing: checkIn.drawingId != nil,
            drawingId: drawing?.id,
            drawingImageURL: drawing?.imageURL,
            reflectiveQuestion: drawing?.reflectiveQuestion,
            reflectiveAnswer: drawing?.reflectiveAnswer,
            journalTitle: journal?.title,
            journalContent: journal?.content,
            checkinId: checkIn.id ?? "",
            recordedEmotion: emotion
        )
    }
}
