//
//  JournalEditorViewModel.swift
//  Soulverse
//
//  ViewModel for the journal editor screen. Handles state and submission
//  via FirestoreJournalService. Uses delegate pattern (no closures) for VC binding.
//

import Foundation

protocol JournalEditorViewModelDelegate: AnyObject {
    func journalEditorViewModelDidUpdateState(_ viewModel: JournalEditorViewModel)
    func journalEditorViewModel(_ viewModel: JournalEditorViewModel, didSaveJournalId journalId: String)
    func journalEditorViewModel(_ viewModel: JournalEditorViewModel, didFailWithError error: Error)
}

final class JournalEditorViewModel {

    weak var delegate: JournalEditorViewModelDelegate?

    let checkinId: String
    private(set) var title: String = ""
    private(set) var content: String = ""
    private(set) var isSaving: Bool = false

    private let service: JournalServiceProtocol

    init(checkinId: String, service: JournalServiceProtocol = FirestoreJournalService.shared) {
        self.checkinId = checkinId
        self.service = service
    }

    var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && !trimmedContent.isEmpty && !isSaving
    }

    func updateTitle(_ text: String) {
        guard text != title else { return }
        title = text
        delegate?.journalEditorViewModelDidUpdateState(self)
    }

    func updateContent(_ text: String) {
        guard text != content else { return }
        content = text
        delegate?.journalEditorViewModelDidUpdateState(self)
    }

    func submit() {
        guard canSave else { return }
        guard let uid = User.shared.userId else {
            assertionFailure("JournalEditor reached without a signed-in user")
            return
        }

        isSaving = true
        delegate?.journalEditorViewModelDidUpdateState(self)

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        service.submitJournal(
            uid: uid,
            checkinId: checkinId,
            title: trimmedTitle,
            content: trimmedContent,
            prompt: nil
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSaving = false
                self.delegate?.journalEditorViewModelDidUpdateState(self)
                switch result {
                case .success(let journalId):
                    self.delegate?.journalEditorViewModel(self, didSaveJournalId: journalId)
                case .failure(let error):
                    self.delegate?.journalEditorViewModel(self, didFailWithError: error)
                }
            }
        }
    }
}
