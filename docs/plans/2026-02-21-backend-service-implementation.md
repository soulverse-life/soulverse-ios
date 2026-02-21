# Backend Service Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement Firestore + Firebase Storage backend services for mood check-ins, drawings, and journals.

**Architecture:** Firestore subcollections under `users/{uid}/` for data, Firebase Storage for binary files (images, PKDrawing recordings). Static service classes following the existing `FirestoreUserService` pattern. All queries are user-scoped.

**Tech Stack:** FirebaseFirestore, FirebaseStorage, PencilKit, Swift

**Design Doc:** `docs/plans/2026-02-21-backend-service-design.md`

---

### Task 1: Add Firebase Storage Dependency

**Files:**
- Modify: `Podfile:28-39`

**Step 1: Add FirebaseStorage pod**

In `Podfile`, add after the existing Firebase pods (line 38):

```ruby
pod 'FirebaseStorage'
```

The block should look like:

```ruby
pod 'Firebase/Crashlytics'
pod 'Firebase/Messaging'
pod 'FirebaseStorage'
pod 'GoogleUtilities'
```

**Step 2: Install pods**

Run:
```bash
cd /Users/mingshing/Soulverse && pod install
```

Expected: `Pod installation complete!` with FirebaseStorage added.

**Step 3: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Podfile Podfile.lock
git commit -m "chore: add FirebaseStorage dependency"
```

---

### Task 2: Create MoodCheckInModel (Firestore Document Model)

**Files:**
- Create: `Soulverse/Shared/Service/MoodCheckInService/MoodCheckInModel.swift`

**Reference pattern:** `Soulverse/Shared/Service/UserService/UserModel.swift` (uses `@DocumentID`, `@ServerTimestamp`, `CodingKeys`)

**Step 1: Create the model file**

```swift
//
//  MoodCheckInModel.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

struct MoodCheckInModel: Codable {
    @DocumentID var id: String?

    // Sensing
    let colorHex: String
    let colorIntensity: Double

    // Naming
    let emotion: String

    // Attributing
    let topic: String

    // Evaluating
    let evaluation: String

    // Journal (optional)
    var journal: String?

    // Timezone
    let timezoneOffsetMinutes: Int

    // Timestamps
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case colorHex
        case colorIntensity
        case emotion
        case topic
        case evaluation
        case journal
        case timezoneOffsetMinutes
        case createdAt
        case updatedAt
    }
}
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Soulverse/Shared/Service/MoodCheckInService/MoodCheckInModel.swift
git commit -m "feat: add MoodCheckInModel for Firestore mood check-in documents"
```

---

### Task 3: Create DrawingModel (Firestore Document Model)

**Files:**
- Create: `Soulverse/Shared/Service/DrawingService/DrawingModel.swift`

**Step 1: Create the model file**

```swift
//
//  DrawingModel.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

struct DrawingModel: Codable {
    @DocumentID var id: String?

    // Relationship
    var checkinId: String?
    let isFromCheckIn: Bool

    // Files (Firebase Storage URLs)
    let imageURL: String
    let recordingURL: String
    var thumbnailURL: String?

    // Metadata
    var promptUsed: String?

    // Timezone
    let timezoneOffsetMinutes: Int

    // Timestamps
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case checkinId
        case isFromCheckIn
        case imageURL
        case recordingURL
        case thumbnailURL
        case promptUsed
        case timezoneOffsetMinutes
        case createdAt
        case updatedAt
    }
}
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Soulverse/Shared/Service/DrawingService/DrawingModel.swift
git commit -m "feat: add DrawingModel for Firestore drawing documents"
```

---

### Task 4: Create FirebaseStorageService

**Files:**
- Create: `Soulverse/Shared/Service/FirebaseStorageService.swift`

**Purpose:** Upload/download images and PKDrawing recording files to Firebase Storage. Used by both mood check-in and drawing services.

**Step 1: Create the service file**

```swift
//
//  FirebaseStorageService.swift
//  Soulverse
//

import Foundation
import FirebaseStorage
import UIKit

final class FirebaseStorageService {

    private static let storage = Storage.storage()

    enum StorageError: LocalizedError {
        case imageConversionFailed
        case downloadURLFailed

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image to PNG data"
            case .downloadURLFailed:
                return "Failed to retrieve download URL"
            }
        }
    }

    // MARK: - Upload Drawing Image

    /// Uploads a rendered drawing image (PNG) to Firebase Storage.
    /// Path: users/{uid}/drawings/{drawingId}/image.png
    static func uploadDrawingImage(
        uid: String,
        drawingId: String,
        image: UIImage,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let imageData = image.pngData() else {
            completion(.failure(StorageError.imageConversionFailed))
            return
        }

        let path = "users/\(uid)/drawings/\(drawingId)/image.png"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"

        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(StorageError.downloadURLFailed))
                }
            }
        }
    }

    // MARK: - Upload Drawing Recording

    /// Uploads PKDrawing binary data to Firebase Storage.
    /// Path: users/{uid}/drawings/{drawingId}/recording.pkd
    static func uploadDrawingRecording(
        uid: String,
        drawingId: String,
        recordingData: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let path = "users/\(uid)/drawings/\(drawingId)/recording.pkd"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"

        ref.putData(recordingData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(StorageError.downloadURLFailed))
                }
            }
        }
    }

    // MARK: - Delete Drawing Files

    /// Deletes all files for a drawing (image, recording, thumbnail).
    /// Silently ignores files that don't exist.
    static func deleteDrawingFiles(
        uid: String,
        drawingId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let basePath = "users/\(uid)/drawings/\(drawingId)"
        let fileNames = ["image.png", "recording.pkd", "thumbnail.png"]
        let group = DispatchGroup()
        var firstError: Error?

        for fileName in fileNames {
            group.enter()
            let ref = storage.reference().child("\(basePath)/\(fileName)")
            ref.delete { error in
                // Ignore "object not found" errors (file may not exist)
                if let error = error as NSError?,
                   error.domain == StorageErrorDomain,
                   StorageErrorCode(rawValue: error.code) == .objectNotFound {
                    // File doesn't exist, that's OK
                } else if let error = error, firstError == nil {
                    firstError = error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = firstError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Soulverse/Shared/Service/FirebaseStorageService.swift
git commit -m "feat: add FirebaseStorageService for drawing image and recording uploads"
```

---

### Task 5: Create FirestoreMoodCheckInService

**Files:**
- Create: `Soulverse/Shared/Service/MoodCheckInService/FirestoreMoodCheckInService.swift`

**Reference pattern:** `Soulverse/Shared/Service/FirestoreUserService.swift` (static methods, `Result<T, Error>` completion handlers, `CodingKeys` for field references)

**Step 1: Create the service file**

```swift
//
//  FirestoreMoodCheckInService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreMoodCheckInService {

    private static let db = Firestore.firestore()

    private typealias Field = MoodCheckInModel.CodingKeys

    enum ServiceError: LocalizedError {
        case userNotLoggedIn
        case documentNotFound

        var errorDescription: String? {
            switch self {
            case .userNotLoggedIn:
                return "User is not logged in"
            case .documentNotFound:
                return "Mood check-in document not found"
            }
        }
    }

    /// Returns the mood_checkins subcollection reference for a user.
    private static func checkInsCollection(uid: String) -> CollectionReference {
        return db.collection("users").document(uid).collection("mood_checkins")
    }

    // MARK: - Submit Mood Check-In

    /// Creates a new mood check-in document in Firestore.
    /// Returns the auto-generated document ID on success.
    static func submitMoodCheckIn(
        uid: String,
        data: MoodCheckInData,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let docRef = checkInsCollection(uid: uid).document()

        let timezoneOffset = TimeZone.current.secondsFromGMT() / 60

        var fields: [String: Any] = [
            Field.colorHex.rawValue: data.colorHexString ?? "",
            Field.colorIntensity.rawValue: data.colorIntensity,
            Field.emotion.rawValue: data.recordedEmotion?.uniqueKey ?? "",
            Field.topic.rawValue: data.selectedTopic?.rawValue ?? "",
            Field.evaluation.rawValue: data.evaluation?.rawValue ?? "",
            Field.timezoneOffsetMinutes.rawValue: timezoneOffset,
            Field.createdAt.rawValue: FieldValue.serverTimestamp(),
            Field.updatedAt.rawValue: FieldValue.serverTimestamp()
        ]

        if let journal = data.journal {
            fields[Field.journal.rawValue] = journal
        }

        docRef.setData(fields) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(docRef.documentID))
            }
        }
    }

    // MARK: - Fetch Latest Check-Ins

    /// Fetches the latest N mood check-ins for a user, ordered by createdAt descending.
    static func fetchLatestCheckIns(
        uid: String,
        limit: Int,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    ) {
        checkInsCollection(uid: uid)
            .order(by: Field.createdAt.rawValue, descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let checkIns = documents.compactMap { doc in
                    try? doc.data(as: MoodCheckInModel.self)
                }
                completion(.success(checkIns))
            }
    }

    // MARK: - Fetch Check-Ins by Date Range

    /// Fetches mood check-ins within a date range, ordered by createdAt ascending.
    static func fetchCheckIns(
        uid: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    ) {
        checkInsCollection(uid: uid)
            .whereField(Field.createdAt.rawValue, isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField(Field.createdAt.rawValue, isLessThan: Timestamp(date: endDate))
            .order(by: Field.createdAt.rawValue, descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let checkIns = documents.compactMap { doc in
                    try? doc.data(as: MoodCheckInModel.self)
                }
                completion(.success(checkIns))
            }
    }

    // MARK: - Delete Check-In

    /// Deletes a mood check-in document.
    static func deleteCheckIn(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        checkInsCollection(uid: uid).document(checkinId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED. If `uniqueKey` is not found on `RecordedEmotion`, check the property name in `Soulverse/MoodCheckIn/Models/RecordedEmotion.swift` — it may be named differently. Adjust accordingly.

**Step 3: Commit**

```bash
git add Soulverse/Shared/Service/MoodCheckInService/FirestoreMoodCheckInService.swift
git commit -m "feat: add FirestoreMoodCheckInService for Firestore mood check-in CRUD"
```

---

### Task 6: Create FirestoreDrawingService

**Files:**
- Create: `Soulverse/Shared/Service/DrawingService/FirestoreDrawingService.swift`

**Step 1: Create the service file**

```swift
//
//  FirestoreDrawingService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore
import UIKit

final class FirestoreDrawingService {

    private static let db = Firestore.firestore()

    private typealias Field = DrawingModel.CodingKeys

    enum ServiceError: LocalizedError {
        case documentNotFound

        var errorDescription: String? {
            switch self {
            case .documentNotFound:
                return "Drawing document not found"
            }
        }
    }

    /// Returns the drawings subcollection reference for a user.
    private static func drawingsCollection(uid: String) -> CollectionReference {
        return db.collection("users").document(uid).collection("drawings")
    }

    // MARK: - Submit Drawing

    /// Uploads image + recording to Storage, then creates Firestore document.
    /// Returns the auto-generated drawing document ID on success.
    static func submitDrawing(
        uid: String,
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        isFromCheckIn: Bool,
        promptUsed: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Generate document ID first so Storage paths use the same ID
        let docRef = drawingsCollection(uid: uid).document()
        let drawingId = docRef.documentID

        // Step 1: Upload image
        FirebaseStorageService.uploadDrawingImage(uid: uid, drawingId: drawingId, image: image) { imageResult in
            switch imageResult {
            case .failure(let error):
                completion(.failure(error))
                return

            case .success(let imageURL):
                // Step 2: Upload recording
                FirebaseStorageService.uploadDrawingRecording(uid: uid, drawingId: drawingId, recordingData: recordingData) { recordingResult in
                    switch recordingResult {
                    case .failure(let error):
                        completion(.failure(error))
                        return

                    case .success(let recordingURL):
                        // Step 3: Create Firestore document
                        let timezoneOffset = TimeZone.current.secondsFromGMT() / 60

                        var fields: [String: Any] = [
                            Field.isFromCheckIn.rawValue: isFromCheckIn,
                            Field.imageURL.rawValue: imageURL,
                            Field.recordingURL.rawValue: recordingURL,
                            Field.timezoneOffsetMinutes.rawValue: timezoneOffset,
                            Field.createdAt.rawValue: FieldValue.serverTimestamp(),
                            Field.updatedAt.rawValue: FieldValue.serverTimestamp()
                        ]

                        if let checkinId = checkinId {
                            fields[Field.checkinId.rawValue] = checkinId
                        }
                        if let promptUsed = promptUsed {
                            fields[Field.promptUsed.rawValue] = promptUsed
                        }

                        docRef.setData(fields) { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(drawingId))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Fetch Drawings by Date Range

    /// Fetches drawings within a date range, ordered by createdAt descending.
    static func fetchDrawings(
        uid: String,
        from startDate: Date,
        to endDate: Date? = nil,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    ) {
        var query: Query = drawingsCollection(uid: uid)
            .whereField(Field.createdAt.rawValue, isGreaterThanOrEqualTo: Timestamp(date: startDate))

        if let endDate = endDate {
            query = query.whereField(Field.createdAt.rawValue, isLessThan: Timestamp(date: endDate))
        }

        query
            .order(by: Field.createdAt.rawValue, descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let drawings = documents.compactMap { doc in
                    try? doc.data(as: DrawingModel.self)
                }
                completion(.success(drawings))
            }
    }

    // MARK: - Fetch Drawings by Check-In ID

    /// Fetches all drawings linked to a specific check-in.
    static func fetchDrawings(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    ) {
        drawingsCollection(uid: uid)
            .whereField(Field.checkinId.rawValue, isEqualTo: checkinId)
            .order(by: Field.createdAt.rawValue, descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let drawings = documents.compactMap { doc in
                    try? doc.data(as: DrawingModel.self)
                }
                completion(.success(drawings))
            }
    }

    // MARK: - Delete Drawing

    /// Deletes a drawing document and its associated Storage files.
    static func deleteDrawing(
        uid: String,
        drawingId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Delete Firestore document first
        drawingsCollection(uid: uid).document(drawingId).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            // Then delete Storage files (best-effort)
            FirebaseStorageService.deleteDrawingFiles(uid: uid, drawingId: drawingId) { _ in
                // Storage cleanup is best-effort; report success regardless
                completion(.success(()))
            }
        }
    }
}
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Soulverse/Shared/Service/DrawingService/FirestoreDrawingService.swift
git commit -m "feat: add FirestoreDrawingService for drawing upload and Firestore CRUD"
```

---

### Task 7: Update MoodCheckInData to Support Journal

**Files:**
- Modify: `Soulverse/MoodCheckIn/Models/MoodCheckInData.swift`

**Purpose:** Add `journal` field. Keep the Shaping fields for now (removal is a UI task tracked separately) but make shaping always complete.

**Step 1: Add journal property**

Add after the Evaluating Step section (after line 43 `var evaluation: EvaluationOption?`):

```swift
    // MARK: - Journal (optional)

    /// Free-form journal text, replaces the old prompt response
    var journal: String?
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Soulverse/MoodCheckIn/Models/MoodCheckInData.swift
git commit -m "feat: add journal field to MoodCheckInData"
```

---

### Task 8: Update MoodCheckInCoordinator to Submit via Firestore

**Files:**
- Modify: `Soulverse/MoodCheckIn/Presenter/MoodCheckInCoordinator.swift:139-162`

**Purpose:** Replace the Moya API call with Firestore submission.

**Step 1: Replace `submitMoodCheckInData()` method**

Replace the current implementation (lines 139-153):

```swift
    private func submitMoodCheckInData() {
        // Make API call
        MoodCheckInAPIServiceProvider.request(.submitMoodCheckIn(moodCheckInData)) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.handleSubmissionSuccess()

            case .failure:
                // For now, still show success (can add error handling later)
                self.handleSubmissionSuccess()
            }
        }
    }
```

With:

```swift
    private func submitMoodCheckInData() {
        guard let uid = User.shared.userId else {
            handleSubmissionSuccess()
            return
        }

        FirestoreMoodCheckInService.submitMoodCheckIn(uid: uid, data: moodCheckInData) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let checkinId):
                self.lastSubmittedCheckinId = checkinId
                self.handleSubmissionSuccess()

            case .failure:
                // For now, still show success (can add error handling later)
                self.handleSubmissionSuccess()
            }
        }
    }
```

Also add a property to store the check-in ID (after line 20 `private var selectedAction: MoodCheckInActingAction?`):

```swift
    private(set) var lastSubmittedCheckinId: String?
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Soulverse/MoodCheckIn/Presenter/MoodCheckInCoordinator.swift
git commit -m "feat: switch mood check-in submission from REST API to Firestore"
```

---

### Task 9: Create MoodEntriesDataAssembler

**Files:**
- Create: `Soulverse/Shared/Service/MoodCheckInService/MoodEntriesDataAssembler.swift`

**Purpose:** Implements the card assembly logic — fetches check-ins and drawings, groups them into day-based cards following the design doc rules.

**Step 1: Create the assembler file**

```swift
//
//  MoodEntriesDataAssembler.swift
//  Soulverse
//

import Foundation

/// Represents a single card in the MoodEntriesSection.
/// Can be a check-in card (with optional drawings) or an orphan card (drawings only).
struct MoodEntryCard {

    /// The mood check-in data, nil for orphan (drawing-only) cards.
    let checkIn: MoodCheckInModel?

    /// Drawings associated with this card (max display count enforced by UI).
    let drawings: [DrawingModel]

    /// The date this card represents.
    let date: Date

    /// Whether this is an orphan card (no check-in, drawings only).
    var isOrphan: Bool {
        return checkIn == nil
    }
}

/// Assembles MoodEntryCards from check-ins and drawings.
///
/// Card assembly rules:
/// 1. Each check-in becomes its own card
/// 2. Drawings with checkinId attach to that check-in's card
/// 3. Standalone drawings between check-ins attach to the preceding check-in's card
/// 4. Drawings on days with no check-in become orphan cards (grouped by day)
/// 5. Multiple check-ins per day produce multiple cards
final class MoodEntriesDataAssembler {

    /// Fetches the latest X check-ins and associated drawings, then assembles cards.
    static func fetchAndAssemble(
        uid: String,
        checkInLimit: Int,
        completion: @escaping (Result<[MoodEntryCard], Error>) -> Void
    ) {
        // Step 1: Fetch latest X check-ins
        FirestoreMoodCheckInService.fetchLatestCheckIns(uid: uid, limit: checkInLimit) { checkInResult in
            switch checkInResult {
            case .failure(let error):
                completion(.failure(error))
                return

            case .success(let checkIns):
                guard !checkIns.isEmpty else {
                    // No check-ins — fetch recent drawings as orphan cards
                    fetchOrphanDrawings(uid: uid, completion: completion)
                    return
                }

                // Step 2: Derive date range from oldest check-in
                guard let oldestDate = checkIns.last?.createdAt else {
                    completion(.success([]))
                    return
                }

                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: oldestDate)

                // Step 3: Fetch all drawings in date range
                FirestoreDrawingService.fetchDrawings(uid: uid, from: startOfDay) { drawingResult in
                    switch drawingResult {
                    case .failure(let error):
                        completion(.failure(error))
                        return

                    case .success(let drawings):
                        // Step 4: Assemble cards
                        let cards = assembleCards(checkIns: checkIns, drawings: drawings)
                        completion(.success(cards))
                    }
                }
            }
        }
    }

    /// Assembles cards from check-ins and drawings.
    /// Check-ins should be sorted by createdAt descending.
    /// Drawings should be sorted by createdAt descending.
    static func assembleCards(
        checkIns: [MoodCheckInModel],
        drawings: [DrawingModel]
    ) -> [MoodEntryCard] {
        let calendar = Calendar.current

        // Sort check-ins by date ascending for interval-based assignment
        let sortedCheckIns = checkIns.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }

        // Separate drawings: linked (have checkinId) vs standalone
        var linkedDrawings: [String: [DrawingModel]] = [:]
        var standaloneDrawings: [DrawingModel] = []

        for drawing in drawings {
            if let checkinId = drawing.checkinId {
                linkedDrawings[checkinId, default: []].append(drawing)
            } else {
                standaloneDrawings.append(drawing)
            }
        }

        // Sort standalone drawings by date ascending for interval assignment
        let sortedStandalone = standaloneDrawings.sorted {
            ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
        }

        // Assign standalone drawings to check-ins or orphan buckets
        var checkInDrawings: [String: [DrawingModel]] = linkedDrawings
        var orphanDrawingsByDay: [DateComponents: [DrawingModel]] = [:]

        for drawing in sortedStandalone {
            guard let drawingDate = drawing.createdAt else { continue }

            // Find the preceding check-in (latest check-in before this drawing)
            let precedingCheckIn = sortedCheckIns.last { checkIn in
                guard let checkInDate = checkIn.createdAt else { return false }
                return checkInDate <= drawingDate
            }

            if let checkIn = precedingCheckIn, let checkInId = checkIn.id {
                // Same day check — attach to preceding check-in
                checkInDrawings[checkInId, default: []].append(drawing)
            } else {
                // No preceding check-in — orphan card grouped by day
                let dayComponents = calendar.dateComponents([.year, .month, .day], from: drawingDate)
                orphanDrawingsByDay[dayComponents, default: []].append(drawing)
            }
        }

        // Build cards from check-ins
        var cards: [MoodEntryCard] = sortedCheckIns.map { checkIn in
            let drawings = checkInDrawings[checkIn.id ?? "", default: []]
                .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            return MoodEntryCard(
                checkIn: checkIn,
                drawings: drawings,
                date: checkIn.createdAt ?? Date()
            )
        }

        // Build orphan cards from drawing-only days
        for (_, dayDrawings) in orphanDrawingsByDay {
            let sorted = dayDrawings.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            if let firstDate = sorted.first?.createdAt {
                cards.append(MoodEntryCard(
                    checkIn: nil,
                    drawings: sorted,
                    date: firstDate
                ))
            }
        }

        // Sort all cards by date descending (most recent first)
        cards.sort { $0.date > $1.date }

        return cards
    }

    // MARK: - Private

    /// Fetches recent drawings when there are no check-ins (all become orphan cards).
    private static func fetchOrphanDrawings(
        uid: String,
        completion: @escaping (Result<[MoodEntryCard], Error>) -> Void
    ) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        FirestoreDrawingService.fetchDrawings(uid: uid, from: sevenDaysAgo) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let drawings):
                let calendar = Calendar.current
                var byDay: [DateComponents: [DrawingModel]] = [:]

                for drawing in drawings {
                    guard let date = drawing.createdAt else { continue }
                    let day = calendar.dateComponents([.year, .month, .day], from: date)
                    byDay[day, default: []].append(drawing)
                }

                let cards: [MoodEntryCard] = byDay.compactMap { _, dayDrawings in
                    let sorted = dayDrawings.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
                    guard let firstDate = sorted.first?.createdAt else { return nil }
                    return MoodEntryCard(checkIn: nil, drawings: sorted, date: firstDate)
                }.sorted { $0.date > $1.date }

                completion(.success(cards))
            }
        }
    }
}
```

**Step 2: Verify build**

Run:
```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Soulverse/Shared/Service/MoodCheckInService/MoodEntriesDataAssembler.swift
git commit -m "feat: add MoodEntriesDataAssembler for card assembly from check-ins and drawings"
```

---

### Task 10: Deploy Firestore Security Rules

**This is a manual Firebase Console task, not code.**

**Step 1: Deploy Firestore rules**

Go to [Firebase Console](https://console.firebase.google.com/project/soulverse-35106/firestore/rules) and replace the rules with the content from the design doc (Section: Security Rules > Firestore).

**Step 2: Deploy Storage rules**

Go to [Firebase Console](https://console.firebase.google.com/project/soulverse-35106/storage/rules) and replace the rules with the content from the design doc (Section: Security Rules > Firebase Storage).

**Step 3: Create composite index**

Go to [Firestore Indexes](https://console.firebase.google.com/project/soulverse-35106/firestore/indexes) and create:
- Collection: `drawings` (subcollection of `users/{uid}`)
- Fields: `checkinId` ASC, `createdAt` ASC

Alternatively, the index will be auto-suggested by Firestore when the first query using both fields runs — the error message will include a direct link to create the index.

**Step 4: Commit a note**

No code to commit. If you set up Firebase CLI later, you can manage rules as files:
```bash
# Future: firebase deploy --only firestore:rules,storage
```

---

## Summary

| Task | Description | Dependencies |
|---|---|---|
| 1 | Add FirebaseStorage pod | None |
| 2 | Create MoodCheckInModel | None |
| 3 | Create DrawingModel | None |
| 4 | Create FirebaseStorageService | Task 1 |
| 5 | Create FirestoreMoodCheckInService | Task 2 |
| 6 | Create FirestoreDrawingService | Tasks 3, 4 |
| 7 | Add journal to MoodCheckInData | None |
| 8 | Update MoodCheckInCoordinator | Tasks 5, 7 |
| 9 | Create MoodEntriesDataAssembler | Tasks 5, 6 |
| 10 | Deploy Firestore security rules | Manual, any time |

**Parallel execution possible:** Tasks 1-3 and 7 have no dependencies and can be done in parallel. Task 4 requires Task 1. Tasks 5-6 require Tasks 2-4. Tasks 8-9 require Tasks 5-7.
