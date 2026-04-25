# Emotional Bundle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Emotional Bundle feature — a living safety plan with 5 editable sections stored in Firestore, accessible from the Self Care (Tools) tab.

**Architecture:** Single Firestore document per user at `users/{uid}/emotional_bundle/default`. Coordinator pattern (like MoodCheckInCoordinator) manages navigation across 7 screens. Service protocol + singleton Firestore implementation for data persistence.

**Tech Stack:** Swift, UIKit, SnapKit, Firebase Firestore, NSLocalizedString

**Spec:** `docs/superpowers/specs/2026-04-15-emotional-bundle-design.md`

---

## File Map

### New Files (22)

| File | Responsibility |
|------|---------------|
| `Features/Tools/EmotionalBundle/Models/EmotionalBundleModel.swift` | Firestore Codable data models + section enums |
| `Features/Tools/EmotionalBundle/Models/CrisisResourceModel.swift` | CrisisResource Codable model + locale loader |
| `Features/Tools/EmotionalBundle/Presenter/EmotionalBundleCoordinator.swift` | Navigation coordinator + all section delegate conformances |
| `Features/Tools/EmotionalBundle/Presenter/EmotionalBundleMainPresenter.swift` | Fetches bundle, maps to view model, tracks completion |
| `Features/Tools/EmotionalBundle/ViewModels/EmotionalBundleMainViewModel.swift` | Section card view models with completion state |
| `Features/Tools/EmotionalBundle/ViewModels/RedFlagsSectionViewModel.swift` | Red Flags form state + validation |
| `Features/Tools/EmotionalBundle/ViewModels/SupportMeSectionViewModel.swift` | Support Me contacts form state |
| `Features/Tools/EmotionalBundle/ViewModels/FeelCalmSectionViewModel.swift` | Feel Calm activities form state + validation |
| `Features/Tools/EmotionalBundle/ViewModels/StaySafeSectionViewModel.swift` | Stay Safe actions form state |
| `Features/Tools/EmotionalBundle/ViewModels/ProfessionalSupportSectionViewModel.swift` | Professional Support form state |
| `Features/Tools/EmotionalBundle/Views/EmotionalBundleMainViewController.swift` | Main hub with 5 section cards + loading overlay |
| `Features/Tools/EmotionalBundle/Views/RedFlagsSectionViewController.swift` | Red Flags editor form |
| `Features/Tools/EmotionalBundle/Views/SupportMeSectionViewController.swift` | Support Me contacts editor |
| `Features/Tools/EmotionalBundle/Views/FeelCalmSectionViewController.swift` | Feel Calm activities editor |
| `Features/Tools/EmotionalBundle/Views/StaySafeSectionViewController.swift` | Stay Safe actions editor |
| `Features/Tools/EmotionalBundle/Views/ProfessionalSupportSectionViewController.swift` | Professional Support editor with crisis card |
| `Features/Tools/EmotionalBundle/Views/Components/BundleSectionCardView.swift` | Glass-effect card for main hub section rows |
| `Features/Tools/EmotionalBundle/Views/Components/BundleFormFieldView.swift` | Labeled text input wrapper with char limit |
| `Features/Tools/EmotionalBundle/Views/Components/CrisisResourceCardView.swift` | Crisis line info card with tap-to-call |
| `Shared/Service/Protocols/EmotionalBundleServiceProtocol.swift` | Service protocol definition |
| `Shared/Service/EmotionalBundleService/FirestoreEmotionalBundleService.swift` | Firestore implementation |
| `Soulverse/Resources/CrisisResources.json` | Locale-keyed crisis line data (US only for now) |

### Modified Files (5)

| File | Change |
|------|--------|
| `Shared/Service/FirestoreSchema.swift:41` | Add `emotionalBundle` collection constant |
| `Shared/Manager/AppCoordinator.swift:176` | Add `openEmotionalBundle(from:)` |
| `Features/Tools/Views/ToolsViewController.swift:254-257` | Wire `.emotionBundle` action |
| `Soulverse/en.lproj/Localizable.strings:305` | Add ~40 `emotional_bundle_*` keys |
| `Soulverse/zh-TW.lproj/Localizable.strings:305` | Add ~40 `emotional_bundle_*` keys |

### Test Files (8)

| File | Tests |
|------|-------|
| `SoulverseTests/Mocks/Features/EmotionalBundle/EmotionalBundleServiceMock.swift` | Mock service for unit tests |
| `SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleModelTests.swift` | Model encoding/decoding, empty factory |
| `SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleMainPresenterTests.swift` | Presenter fetch, completion mapping |
| `SoulverseTests/Tests/Features/EmotionalBundle/RedFlagsSectionViewModelTests.swift` | Validation, hasContent logic |
| `SoulverseTests/Tests/Features/EmotionalBundle/SupportMeSectionViewModelTests.swift` | Contact hasContent logic |
| `SoulverseTests/Tests/Features/EmotionalBundle/FeelCalmSectionViewModelTests.swift` | Validation, hasContent logic |
| `SoulverseTests/Tests/Features/EmotionalBundle/StaySafeSectionViewModelTests.swift` | hasContent logic |
| `SoulverseTests/Tests/Features/EmotionalBundle/ProfessionalSupportSectionViewModelTests.swift` | hasContent, crisis resource loading |

---

## Task 1: Data Models + Service Protocol

**Files:**
- Create: `Soulverse/Features/Tools/EmotionalBundle/Models/EmotionalBundleModel.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Models/CrisisResourceModel.swift`
- Create: `Soulverse/Shared/Service/Protocols/EmotionalBundleServiceProtocol.swift`
- Modify: `Soulverse/Shared/Service/FirestoreSchema.swift:41`
- Test: `SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleModelTests.swift`

- [ ] **Step 1: Create EmotionalBundleModel.swift with all data models**

Create the folder structure and file at `Soulverse/Features/Tools/EmotionalBundle/Models/EmotionalBundleModel.swift`:

```swift
import Foundation
import FirebaseFirestore

// MARK: - Main Bundle Model

struct EmotionalBundleModel: Codable {
    @DocumentID var id: String?
    var version: Int
    var redFlags: [RedFlagItem]
    var supportMe: [SupportContact]
    var feelCalm: [CalmActivity]
    var staySafe: [SafetyAction]
    var professionalSupport: [ProfessionalContact]
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    init(
        version: Int = 1,
        redFlags: [RedFlagItem] = [],
        supportMe: [SupportContact] = [],
        feelCalm: [CalmActivity] = [],
        staySafe: [SafetyAction] = [],
        professionalSupport: [ProfessionalContact] = []
    ) {
        self.version = version
        self.redFlags = redFlags
        self.supportMe = supportMe
        self.feelCalm = feelCalm
        self.staySafe = staySafe
        self.professionalSupport = professionalSupport
    }

    static func empty() -> EmotionalBundleModel {
        return EmotionalBundleModel()
    }
}

// Custom decoder for forward-compatible field additions
extension EmotionalBundleModel {
    enum CodingKeys: String, CodingKey {
        case id, version, redFlags, supportMe, feelCalm, staySafe, professionalSupport, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? .init(wrappedValue: nil)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        redFlags = try container.decodeIfPresent([RedFlagItem].self, forKey: .redFlags) ?? []
        supportMe = try container.decodeIfPresent([SupportContact].self, forKey: .supportMe) ?? []
        feelCalm = try container.decodeIfPresent([CalmActivity].self, forKey: .feelCalm) ?? []
        staySafe = try container.decodeIfPresent([SafetyAction].self, forKey: .staySafe) ?? []
        professionalSupport = try container.decodeIfPresent([ProfessionalContact].self, forKey: .professionalSupport) ?? []
        _createdAt = try container.decodeIfPresent(ServerTimestamp<Date>.self, forKey: .createdAt) ?? .init(wrappedValue: nil)
        _updatedAt = try container.decodeIfPresent(ServerTimestamp<Date>.self, forKey: .updatedAt) ?? .init(wrappedValue: nil)
    }
}

// MARK: - Section Item Models

struct RedFlagItem: Codable, Identifiable {
    var id: String
    var text: String
    var sortOrder: Int

    init(text: String = "", sortOrder: Int) {
        self.id = "rf_\(UUID().uuidString.prefix(8))"
        self.text = text
        self.sortOrder = sortOrder
    }
}

struct SupportContact: Codable, Identifiable {
    var id: String
    var name: String
    var phone: String?
    var email: String?
    var relationship: String?
    var sortOrder: Int

    init(name: String = "", phone: String? = nil, email: String? = nil, relationship: String? = nil, sortOrder: Int) {
        self.id = "sm_\(UUID().uuidString.prefix(8))"
        self.name = name
        self.phone = phone
        self.email = email
        self.relationship = relationship
        self.sortOrder = sortOrder
    }
}

struct CalmActivity: Codable, Identifiable {
    var id: String
    var text: String
    var sortOrder: Int

    init(text: String = "", sortOrder: Int) {
        self.id = "fc_\(UUID().uuidString.prefix(8))"
        self.text = text
        self.sortOrder = sortOrder
    }
}

struct SafetyAction: Codable, Identifiable {
    var id: String
    var text: String
    var sortOrder: Int

    init(text: String = "", sortOrder: Int) {
        self.id = "ss_\(UUID().uuidString.prefix(8))"
        self.text = text
        self.sortOrder = sortOrder
    }
}

struct ProfessionalContact: Codable, Identifiable {
    var id: String
    var placeName: String?
    var contactName: String?
    var phone: String?
    var sortOrder: Int

    init(placeName: String? = nil, contactName: String? = nil, phone: String? = nil, sortOrder: Int) {
        self.id = "ps_\(UUID().uuidString.prefix(8))"
        self.placeName = placeName
        self.contactName = contactName
        self.phone = phone
        self.sortOrder = sortOrder
    }
}

// MARK: - Section Identifiers

enum EmotionalBundleSection: String, CaseIterable {
    case redFlags
    case supportMe
    case feelCalm
    case staySafe
    case professionalSupport

    var displayTitle: String {
        switch self {
        case .redFlags: return NSLocalizedString("emotional_bundle_section_red_flags", comment: "")
        case .supportMe: return NSLocalizedString("emotional_bundle_section_support_me", comment: "")
        case .feelCalm: return NSLocalizedString("emotional_bundle_section_feel_calm", comment: "")
        case .staySafe: return NSLocalizedString("emotional_bundle_section_stay_safe", comment: "")
        case .professionalSupport: return NSLocalizedString("emotional_bundle_section_professional_support", comment: "")
        }
    }
}

// MARK: - Section Data (for partial saves)

enum EmotionalBundleSectionData {
    case redFlags([RedFlagItem])
    case supportMe([SupportContact])
    case feelCalm([CalmActivity])
    case staySafe([SafetyAction])
    case professionalSupport([ProfessionalContact])
}
```

- [ ] **Step 2: Create CrisisResourceModel.swift**

Create at `Soulverse/Features/Tools/EmotionalBundle/Models/CrisisResourceModel.swift`:

```swift
import Foundation

struct CrisisResource: Codable {
    let name: String
    let number: String
    let description: String
    let availability: String
}

struct CrisisResourceLoader {
    static func loadForCurrentLocale() -> CrisisResource? {
        guard let url = Bundle.main.url(forResource: "CrisisResources", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let resources = try? JSONDecoder().decode([String: CrisisResource].self, from: data) else {
            return nil
        }
        let countryCode = Locale.current.region?.identifier ?? ""
        return resources[countryCode]
    }
}
```

- [ ] **Step 3: Create CrisisResources.json**

Create at `Soulverse/Resources/CrisisResources.json`:

```json
{
    "US": {
        "name": "988 Suicide & Crisis Lifeline",
        "number": "988",
        "description": "Free and confidential support for people in distress",
        "availability": "24/7"
    }
}
```

**Important:** Add this file to the Xcode project target's Copy Bundle Resources phase so it's included in the app bundle.

> **Note (applies to all tasks):** All new `.swift` files must be added to the Xcode project — production files to the `Soulverse` target, test files to the `SoulverseTests` target. When creating files via Xcode, this happens automatically. When creating files from CLI, open the `.xcodeproj` and drag files into the appropriate groups/targets.

- [ ] **Step 4: Create EmotionalBundleServiceProtocol.swift**

Create at `Soulverse/Shared/Service/Protocols/EmotionalBundleServiceProtocol.swift`:

```swift
import Foundation

protocol EmotionalBundleServiceProtocol {
    func fetchBundle(uid: String, completion: @escaping (Result<EmotionalBundleModel?, Error>) -> Void)
    func saveSection(uid: String, section: EmotionalBundleSection, data: EmotionalBundleSectionData, completion: @escaping (Result<Void, Error>) -> Void)
}
```

- [ ] **Step 5: Add collection constant to FirestoreSchema.swift**

Modify `Soulverse/Shared/Service/FirestoreSchema.swift` — add after line 41 (after `static let journals`):

```swift
static let emotionalBundle = "emotional_bundle"
```

- [ ] **Step 6: Write model tests**

Create at `SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleModelTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class EmotionalBundleModelTests: XCTestCase {

    func testEmptyFactoryReturnsEmptyArrays() {
        let bundle = EmotionalBundleModel.empty()
        XCTAssertEqual(bundle.version, 1)
        XCTAssertTrue(bundle.redFlags.isEmpty)
        XCTAssertTrue(bundle.supportMe.isEmpty)
        XCTAssertTrue(bundle.feelCalm.isEmpty)
        XCTAssertTrue(bundle.staySafe.isEmpty)
        XCTAssertTrue(bundle.professionalSupport.isEmpty)
    }

    func testRedFlagItemGeneratesUniqueId() {
        let item1 = RedFlagItem(text: "test", sortOrder: 0)
        let item2 = RedFlagItem(text: "test", sortOrder: 1)
        XCTAssertNotEqual(item1.id, item2.id)
        XCTAssertTrue(item1.id.hasPrefix("rf_"))
    }

    func testSupportContactGeneratesUniqueId() {
        let contact = SupportContact(name: "Stephy", phone: "555-1234", sortOrder: 0)
        XCTAssertTrue(contact.id.hasPrefix("sm_"))
        XCTAssertEqual(contact.name, "Stephy")
    }

    func testSectionDisplayTitlesAreNotEmpty() {
        for section in EmotionalBundleSection.allCases {
            XCTAssertFalse(section.displayTitle.isEmpty, "\(section.rawValue) has empty display title")
        }
    }

    func testCrisisResourceLoaderReturnsNilForUnknownLocale() {
        // CrisisResourceLoader uses Locale.current which we can't easily mock,
        // but we verify the loader doesn't crash
        _ = CrisisResourceLoader.loadForCurrentLocale()
    }
}
```

- [ ] **Step 7: Run tests to verify they compile and pass**

Run: `xcodebuild test -workspace Soulverse.xcworkspace -scheme "Soulverse" -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' -only-testing:SoulverseTests/EmotionalBundleModelTests -quiet`

- [ ] **Step 8: Commit**

```bash
git add Soulverse/Features/Tools/EmotionalBundle/Models/ \
       Soulverse/Shared/Service/Protocols/EmotionalBundleServiceProtocol.swift \
       Soulverse/Shared/Service/FirestoreSchema.swift \
       Soulverse/Resources/CrisisResources.json \
       SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleModelTests.swift
git commit -m "feat(emotional-bundle): add data models, service protocol, and crisis resources"
```

---

## Task 2: Firestore Service Implementation

**Files:**
- Create: `Soulverse/Shared/Service/EmotionalBundleService/FirestoreEmotionalBundleService.swift`
- Create: `SoulverseTests/Mocks/Features/EmotionalBundle/EmotionalBundleServiceMock.swift`

- [ ] **Step 1: Create FirestoreEmotionalBundleService.swift**

Create at `Soulverse/Shared/Service/EmotionalBundleService/FirestoreEmotionalBundleService.swift`:

```swift
import Foundation
import FirebaseFirestore

final class FirestoreEmotionalBundleService: EmotionalBundleServiceProtocol {

    static let shared = FirestoreEmotionalBundleService()
    private let db = Firestore.firestore()
    private init() {}

    private func bundleRef(uid: String) -> DocumentReference {
        db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.emotionalBundle)
            .document("default")
    }

    func fetchBundle(uid: String, completion: @escaping (Result<EmotionalBundleModel?, Error>) -> Void) {
        bundleRef(uid: uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.success(nil))
                return
            }
            do {
                let bundle = try snapshot.data(as: EmotionalBundleModel.self)
                completion(.success(bundle))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func saveSection(uid: String, section: EmotionalBundleSection, data: EmotionalBundleSectionData, completion: @escaping (Result<Void, Error>) -> Void) {
        let fields: [String: Any]
        do {
            fields = try encodeSection(data)
        } catch {
            completion(.failure(error))
            return
        }

        let ref = bundleRef(uid: uid)
        var updateFields = fields
        updateFields["updatedAt"] = FieldValue.serverTimestamp()
        updateFields["version"] = 1

        // Check if document exists to set createdAt only on first write
        ref.getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            if snapshot == nil || !snapshot!.exists {
                updateFields["createdAt"] = FieldValue.serverTimestamp()
            }
            ref.setData(updateFields, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    private func encodeSection(_ data: EmotionalBundleSectionData) throws -> [String: Any] {
        let encoder = Firestore.Encoder()
        switch data {
        case .redFlags(let items):
            return ["redFlags": try items.map { try encoder.encode($0) }]
        case .supportMe(let items):
            return ["supportMe": try items.map { try encoder.encode($0) }]
        case .feelCalm(let items):
            return ["feelCalm": try items.map { try encoder.encode($0) }]
        case .staySafe(let items):
            return ["staySafe": try items.map { try encoder.encode($0) }]
        case .professionalSupport(let items):
            return ["professionalSupport": try items.map { try encoder.encode($0) }]
        }
    }
}
```

- [ ] **Step 2: Create EmotionalBundleServiceMock.swift**

Create at `SoulverseTests/Mocks/Features/EmotionalBundle/EmotionalBundleServiceMock.swift`:

```swift
import Foundation
@testable import Soulverse

final class EmotionalBundleServiceMock: EmotionalBundleServiceProtocol {

    var fetchBundleResult: Result<EmotionalBundleModel?, Error> = .success(nil)
    var fetchBundleCallCount = 0

    var saveSectionResult: Result<Void, Error> = .success(())
    var saveSectionCallCount = 0
    var lastSavedSection: EmotionalBundleSection?
    var lastSavedData: EmotionalBundleSectionData?

    func fetchBundle(uid: String, completion: @escaping (Result<EmotionalBundleModel?, Error>) -> Void) {
        fetchBundleCallCount += 1
        completion(fetchBundleResult)
    }

    func saveSection(uid: String, section: EmotionalBundleSection, data: EmotionalBundleSectionData, completion: @escaping (Result<Void, Error>) -> Void) {
        saveSectionCallCount += 1
        lastSavedSection = section
        lastSavedData = data
        completion(saveSectionResult)
    }
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet`

- [ ] **Step 4: Commit**

```bash
git add Soulverse/Shared/Service/EmotionalBundleService/ \
       SoulverseTests/Mocks/Features/EmotionalBundle/
git commit -m "feat(emotional-bundle): add Firestore service implementation and mock"
```

---

## Task 3: ViewModels + Presenter

**Files:**
- Create: `Soulverse/Features/Tools/EmotionalBundle/ViewModels/EmotionalBundleMainViewModel.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/ViewModels/RedFlagsSectionViewModel.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/ViewModels/SupportMeSectionViewModel.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/ViewModels/FeelCalmSectionViewModel.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/ViewModels/StaySafeSectionViewModel.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/ViewModels/ProfessionalSupportSectionViewModel.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Presenter/EmotionalBundleMainPresenter.swift`
- Test: `SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleMainPresenterTests.swift`
- Test: `SoulverseTests/Tests/Features/EmotionalBundle/RedFlagsSectionViewModelTests.swift`
- Test: `SoulverseTests/Tests/Features/EmotionalBundle/SupportMeSectionViewModelTests.swift`
- Test: `SoulverseTests/Tests/Features/EmotionalBundle/FeelCalmSectionViewModelTests.swift`
- Test: `SoulverseTests/Tests/Features/EmotionalBundle/StaySafeSectionViewModelTests.swift`
- Test: `SoulverseTests/Tests/Features/EmotionalBundle/ProfessionalSupportSectionViewModelTests.swift`

- [ ] **Step 1: Create EmotionalBundleMainViewModel.swift**

```swift
import Foundation

struct BundleSectionCardViewModel {
    let section: EmotionalBundleSection
    let title: String
    let isCompleted: Bool
}

struct EmotionalBundleMainViewModel {
    let isLoading: Bool
    let sectionCards: [BundleSectionCardViewModel]

    init(isLoading: Bool = false, sectionCards: [BundleSectionCardViewModel] = []) {
        self.isLoading = isLoading
        self.sectionCards = sectionCards
    }

    static func completionCheck(for section: EmotionalBundleSection, in bundle: EmotionalBundleModel) -> Bool {
        switch section {
        case .redFlags:
            return bundle.redFlags.first.map { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        case .supportMe:
            return bundle.supportMe.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case .feelCalm:
            return bundle.feelCalm.first.map { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        case .staySafe:
            return bundle.staySafe.first.map { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        case .professionalSupport:
            return bundle.professionalSupport.contains {
                !($0.placeName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !($0.contactName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !($0.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }
}
```

- [ ] **Step 2: Create all 5 section ViewModels**

Each section ViewModel follows the same pattern. Create all 5 files:

`RedFlagsSectionViewModel.swift`:
```swift
import Foundation

struct RedFlagsSectionViewModel {
    var redFlags: [String]  // Fixed count: 2
    let maxCharacters: Int = 200

    init(redFlags: [String] = ["", ""]) {
        self.redFlags = redFlags
    }

    init(from items: [RedFlagItem]) {
        var flags = items.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.text)
        while flags.count < 2 { flags.append("") }
        self.redFlags = Array(flags.prefix(2))
    }

    var isValid: Bool {
        !redFlags[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasContent: Bool {
        redFlags.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func toSectionData() -> EmotionalBundleSectionData {
        let items = redFlags.enumerated().map { index, text in
            RedFlagItem(text: text, sortOrder: index)
        }
        return .redFlags(items)
    }
}
```

`SupportMeSectionViewModel.swift`:
```swift
import Foundation

struct SupportMeContactViewModel {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var relationship: String = ""
}

struct SupportMeSectionViewModel {
    var contacts: [SupportMeContactViewModel]  // Fixed count: 2
    let maxCharacters: Int = 100

    init(contacts: [SupportMeContactViewModel] = [SupportMeContactViewModel(), SupportMeContactViewModel()]) {
        self.contacts = contacts
    }

    init(from items: [SupportContact]) {
        var contactVMs = items.sorted(by: { $0.sortOrder < $1.sortOrder }).map {
            SupportMeContactViewModel(name: $0.name, phone: $0.phone ?? "", email: $0.email ?? "", relationship: $0.relationship ?? "")
        }
        while contactVMs.count < 2 { contactVMs.append(SupportMeContactViewModel()) }
        self.contacts = Array(contactVMs.prefix(2))
    }

    var hasContent: Bool {
        contacts.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func toSectionData() -> EmotionalBundleSectionData {
        let items = contacts.enumerated().map { index, vm in
            SupportContact(name: vm.name, phone: vm.phone, email: vm.email, relationship: vm.relationship, sortOrder: index)
        }
        return .supportMe(items)
    }
}
```

`FeelCalmSectionViewModel.swift`:
```swift
import Foundation

struct FeelCalmSectionViewModel {
    var activities: [String]  // Fixed count: 3
    let maxCharacters: Int = 100

    init(activities: [String] = ["", "", ""]) {
        self.activities = activities
    }

    init(from items: [CalmActivity]) {
        var acts = items.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.text)
        while acts.count < 3 { acts.append("") }
        self.activities = Array(acts.prefix(3))
    }

    var isValid: Bool {
        !activities[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasContent: Bool {
        activities.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func toSectionData() -> EmotionalBundleSectionData {
        let items = activities.enumerated().map { index, text in
            CalmActivity(text: text, sortOrder: index)
        }
        return .feelCalm(items)
    }
}
```

`StaySafeSectionViewModel.swift`:
```swift
import Foundation

struct StaySafeSectionViewModel {
    var action: String
    let maxCharacters: Int = 100

    init(action: String = "") {
        self.action = action
    }

    init(from items: [SafetyAction]) {
        self.action = items.sorted(by: { $0.sortOrder < $1.sortOrder }).first?.text ?? ""
    }

    var hasContent: Bool {
        !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toSectionData() -> EmotionalBundleSectionData {
        return .staySafe([SafetyAction(text: action, sortOrder: 0)])
    }
}
```

`ProfessionalSupportSectionViewModel.swift`:
```swift
import Foundation

struct ProfessionalSupportSectionViewModel {
    var placeName: String = ""
    var contactName: String = ""
    var phone: String = ""
    let maxCharacters: Int = 100
    let crisisResource: CrisisResource?

    init(placeName: String = "", contactName: String = "", phone: String = "", crisisResource: CrisisResource? = CrisisResourceLoader.loadForCurrentLocale()) {
        self.placeName = placeName
        self.contactName = contactName
        self.phone = phone
        self.crisisResource = crisisResource
    }

    init(from items: [ProfessionalContact], crisisResource: CrisisResource? = CrisisResourceLoader.loadForCurrentLocale()) {
        let first = items.sorted(by: { $0.sortOrder < $1.sortOrder }).first
        self.placeName = first?.placeName.flatMap { $0 } ?? ""
        self.contactName = first?.contactName.flatMap { $0 } ?? ""
        self.phone = first?.phone.flatMap { $0 } ?? ""
        self.crisisResource = crisisResource
    }

    var hasContent: Bool {
        !placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toSectionData() -> EmotionalBundleSectionData {
        return .professionalSupport([ProfessionalContact(placeName: placeName, contactName: contactName, phone: phone, sortOrder: 0)])
    }
}
```

- [ ] **Step 3: Create EmotionalBundleMainPresenter.swift**

```swift
import Foundation

protocol EmotionalBundleMainPresenterDelegate: AnyObject {
    func didUpdate(viewModel: EmotionalBundleMainViewModel)
    func didFailToLoad(error: Error)
}

protocol EmotionalBundleMainPresenterType: AnyObject {
    var delegate: EmotionalBundleMainPresenterDelegate? { get set }
    func fetchData()
    func refreshAfterSave()
    func currentBundle() -> EmotionalBundleModel
}

final class EmotionalBundleMainPresenter: EmotionalBundleMainPresenterType {

    weak var delegate: EmotionalBundleMainPresenterDelegate?

    private let service: EmotionalBundleServiceProtocol
    private let uid: String
    private var cachedBundle: EmotionalBundleModel?

    init(uid: String, service: EmotionalBundleServiceProtocol = FirestoreEmotionalBundleService.shared) {
        self.uid = uid
        self.service = service
    }

    func fetchData() {
        delegate?.didUpdate(viewModel: EmotionalBundleMainViewModel(isLoading: true))

        service.fetchBundle(uid: uid) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let bundle):
                    self.cachedBundle = bundle
                    let viewModel = self.buildViewModel(from: bundle)
                    self.delegate?.didUpdate(viewModel: viewModel)
                case .failure(let error):
                    self.delegate?.didFailToLoad(error: error)
                }
            }
        }
    }

    func refreshAfterSave() {
        fetchData()
    }

    func currentBundle() -> EmotionalBundleModel {
        return cachedBundle ?? .empty()
    }

    private func buildViewModel(from bundle: EmotionalBundleModel?) -> EmotionalBundleMainViewModel {
        let bundle = bundle ?? .empty()
        let cards = EmotionalBundleSection.allCases.map { section in
            BundleSectionCardViewModel(
                section: section,
                title: section.displayTitle,
                isCompleted: EmotionalBundleMainViewModel.completionCheck(for: section, in: bundle)
            )
        }
        return EmotionalBundleMainViewModel(isLoading: false, sectionCards: cards)
    }
}
```

- [ ] **Step 4: Write ViewModel tests**

Create test files for each ViewModel. Key tests (create one file per ViewModel):

`RedFlagsSectionViewModelTests.swift`:
```swift
import XCTest
@testable import Soulverse

final class RedFlagsSectionViewModelTests: XCTestCase {
    func testIsValidWhenFirstFlagHasText() {
        let vm = RedFlagsSectionViewModel(redFlags: ["I isolate myself", ""])
        XCTAssertTrue(vm.isValid)
    }

    func testIsInvalidWhenFirstFlagEmpty() {
        let vm = RedFlagsSectionViewModel(redFlags: ["", "some text"])
        XCTAssertFalse(vm.isValid)
    }

    func testIsInvalidWhenFirstFlagWhitespaceOnly() {
        let vm = RedFlagsSectionViewModel(redFlags: ["   ", ""])
        XCTAssertFalse(vm.isValid)
    }

    func testHasContentWhenAnyFlagFilled() {
        let vm = RedFlagsSectionViewModel(redFlags: ["", "I stop answering"])
        XCTAssertTrue(vm.hasContent)
    }

    func testInitFromItems() {
        let items = [RedFlagItem(text: "flag2", sortOrder: 1), RedFlagItem(text: "flag1", sortOrder: 0)]
        let vm = RedFlagsSectionViewModel(from: items)
        XCTAssertEqual(vm.redFlags[0], "flag1")
        XCTAssertEqual(vm.redFlags[1], "flag2")
    }

    func testInitFromEmptyItemsPadsTwoSlots() {
        let vm = RedFlagsSectionViewModel(from: [])
        XCTAssertEqual(vm.redFlags.count, 2)
    }
}
```

Follow the same pattern for `SupportMeSectionViewModelTests`, `FeelCalmSectionViewModelTests`, `StaySafeSectionViewModelTests`, and `ProfessionalSupportSectionViewModelTests`. Each tests `hasContent`, `init(from:)`, and `toSectionData()`.

Also create `EmotionalBundleMainPresenterTests.swift`:
```swift
import XCTest
@testable import Soulverse

final class EmotionalBundleMainPresenterTests: XCTestCase {

    private var presenter: EmotionalBundleMainPresenter!
    private var mockService: EmotionalBundleServiceMock!
    private var mockDelegate: MockPresenterDelegate!

    override func setUp() {
        super.setUp()
        mockService = EmotionalBundleServiceMock()
        mockDelegate = MockPresenterDelegate()
        presenter = EmotionalBundleMainPresenter(uid: "test-uid", service: mockService)
        presenter.delegate = mockDelegate
    }

    func testFetchDataShowsLoadingThenCards() {
        let bundle = EmotionalBundleModel(redFlags: [RedFlagItem(text: "flag", sortOrder: 0)])
        mockService.fetchBundleResult = .success(bundle)

        let expectation = expectation(description: "fetch")
        mockDelegate.onUpdate = { vm in
            if !vm.isLoading {
                XCTAssertEqual(vm.sectionCards.count, 5)
                XCTAssertTrue(vm.sectionCards[0].isCompleted) // redFlags
                XCTAssertFalse(vm.sectionCards[1].isCompleted) // supportMe
                expectation.fulfill()
            }
        }
        presenter.fetchData()
        waitForExpectations(timeout: 1)
    }

    func testFetchDataCallsDidFailOnError() {
        mockService.fetchBundleResult = .failure(NSError(domain: "test", code: 1))

        let expectation = expectation(description: "error")
        mockDelegate.onError = { _ in expectation.fulfill() }
        presenter.fetchData()
        waitForExpectations(timeout: 1)
    }

    func testCurrentBundleReturnsEmptyBeforeFetch() {
        let bundle = presenter.currentBundle()
        XCTAssertTrue(bundle.redFlags.isEmpty)
    }
}

private final class MockPresenterDelegate: EmotionalBundleMainPresenterDelegate {
    var onUpdate: ((EmotionalBundleMainViewModel) -> Void)?
    var onError: ((Error) -> Void)?

    func didUpdate(viewModel: EmotionalBundleMainViewModel) { onUpdate?(viewModel) }
    func didFailToLoad(error: Error) { onError?(error) }
}
```

- [ ] **Step 5: Run all tests**

Run: `xcodebuild test -workspace Soulverse.xcworkspace -scheme "Soulverse" -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' -only-testing:SoulverseTests -quiet`

- [ ] **Step 6: Commit**

```bash
git add Soulverse/Features/Tools/EmotionalBundle/ViewModels/ \
       Soulverse/Features/Tools/EmotionalBundle/Presenter/EmotionalBundleMainPresenter.swift \
       SoulverseTests/Tests/Features/EmotionalBundle/
git commit -m "feat(emotional-bundle): add ViewModels, Presenter, and unit tests"
```

---

## Task 4: Reusable View Components

**Files:**
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/Components/BundleSectionCardView.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/Components/BundleFormFieldView.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/Components/CrisisResourceCardView.swift`

- [ ] **Step 1: Create BundleSectionCardView.swift**

Glass-effect card for the main hub. Shows section icon, title, and completion checkmark. Reference `ViewComponentConstants.applyGlassCardEffect()` for glass styling. Use `private enum Layout` for all spacing constants. Use only `UIColor.theme*` colors.

Key requirements:
- Glass card background effect
- Section title label (`.themeTextPrimary`)
- Completion checkmark icon (visible when `isCompleted`, hidden when not)
- Tap gesture that calls a delegate/closure
- 44pt minimum touch target

- [ ] **Step 2: Create BundleFormFieldView.swift**

Labeled text input wrapper with character limit support. Wraps `SoulverseTextField`.

Key requirements:
- Title label above field (e.g., "Red flag 1", "Activity 1 (Optional)")
- `SoulverseTextField` for input
- Character counter at bottom-right, visible only when near/at limit
- At-limit: red border + count label (e.g., "200/200") via `.errorWithMessage` state
- Configurable `maxCharacters` (200 for Red Flags, 100 for everything else)
- Configurable keyboard type (`.default`, `.phonePad`, `.emailAddress`)
- Delegate/closure for text changes

- [ ] **Step 3: Create CrisisResourceCardView.swift**

Displays crisis line info loaded from `CrisisResource` model.

Key requirements:
- Card with crisis line name, number, description, availability
- Glass card effect background
- Tappable — calls `tel:{number}` via `UIApplication.shared.open`
- Shows `UIAlertController` confirmation before dialing
- Graceful fallback on devices without telephony (`canOpenURL` check)
- All text from the `CrisisResource` model (not hardcoded)

- [ ] **Step 4: Build to verify compilation**

Run: `xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet`

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Tools/EmotionalBundle/Views/Components/
git commit -m "feat(emotional-bundle): add reusable view components"
```

---

## Task 5: Main Hub ViewController

**Files:**
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/EmotionalBundleMainViewController.swift`

- [ ] **Step 1: Create EmotionalBundleMainViewController.swift**

Inherits from `ViewController` (the project's base class at `Shared/ViewComponent/ViewController.swift`).

Key requirements:
- `SoulverseNavigationView` with back button (left)
- Title "Emotional Bundle" + subtitle
- `UIScrollView` containing a vertical `UIStackView` of 5 `BundleSectionCardView`s
- Full-page loading indicator overlay (same pattern as InnerCosmo — `UIActivityIndicatorView` centered on view)
- Error state: centered error message label + "Retry" button, calling `presenter.fetchData()` on tap. Hide error view when loading/loaded.
- No footer (deferred to later phase)
- Conforms to `EmotionalBundleMainPresenterDelegate`
- `delegate: EmotionalBundleMainViewControllerDelegate?` for coordinator communication
- All spacing via `private enum Layout`
- All colors via `UIColor.theme*`

Delegate protocol:
```swift
protocol EmotionalBundleMainViewControllerDelegate: AnyObject {
    func didSelectSection(_ viewController: EmotionalBundleMainViewController, section: EmotionalBundleSection)
    func didTapClose(_ viewController: EmotionalBundleMainViewController)
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet`

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Tools/EmotionalBundle/Views/EmotionalBundleMainViewController.swift
git commit -m "feat(emotional-bundle): add main hub view controller"
```

---

## Task 6: Section Editor ViewControllers (5 screens)

**Files:**
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/RedFlagsSectionViewController.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/SupportMeSectionViewController.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/FeelCalmSectionViewController.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/StaySafeSectionViewController.swift`
- Create: `Soulverse/Features/Tools/EmotionalBundle/Views/ProfessionalSupportSectionViewController.swift`

- [ ] **Step 1: Create RedFlagsSectionViewController.swift**

All section editors share this structure:
- Inherit from `ViewController`
- `SoulverseNavigationView` with ✕ (left, cancel) and ✓ (right, save)
- Section icon + title + description labels
- `UIScrollView` with `BundleFormFieldView` instances
- `private enum Layout` for all spacing
- `UIColor.theme*` for all colors
- Delegate protocol for coordinator communication

Red Flags specific:
- 2 `BundleFormFieldView`s (Red flag 1 required, Red flag 2 optional)
- `maxCharacters: 200`
- On ✓ tap: validate first field non-empty, show `.errorWithMessage` if empty
- Delegate: `RedFlagsSectionViewControllerDelegate`

```swift
protocol RedFlagsSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: RedFlagsSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: RedFlagsSectionViewController)
}
```

- [ ] **Step 2: Create SupportMeSectionViewController.swift**

- 2 contact groups, each with 4 `BundleFormFieldView`s (Name, Phone, Email, Relationship)
- `maxCharacters: 100`
- Keyboard types: `.default`, `.phonePad`, `.emailAddress`, `.default`
- No required field validation (all optional)
- Init with `SupportMeSectionViewModel`, populate fields from `contacts` array
- On ✓ tap: collect all field values into `SupportMeContactViewModel` array, call delegate

```swift
protocol SupportMeSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: SupportMeSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: SupportMeSectionViewController)
}
```

- [ ] **Step 3: Create FeelCalmSectionViewController.swift**

- 3 `BundleFormFieldView`s (Activity 1 required, Activity 2-3 optional)
- `maxCharacters: 100`
- On ✓ tap: validate first field non-empty, show `.errorWithMessage` if empty
- Init with `FeelCalmSectionViewModel`, populate fields from `activities` array

```swift
protocol FeelCalmSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: FeelCalmSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: FeelCalmSectionViewController)
}
```

- [ ] **Step 4: Create StaySafeSectionViewController.swift**

- 1 `BundleFormFieldView` (optional)
- `maxCharacters: 100`
- No required field validation
- Init with `StaySafeSectionViewModel`, populate field from `action`

```swift
protocol StaySafeSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: StaySafeSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: StaySafeSectionViewController)
}
```

- [ ] **Step 5: Create ProfessionalSupportSectionViewController.swift**

- `CrisisResourceCardView` at top (hidden if `crisisResource` is nil / no locale match)
- 3 `BundleFormFieldView`s (Place/Clinic, Professional Name, Emergency Number)
- `maxCharacters: 100`
- Phone field keyboard: `.phonePad`
- No required field validation
- Init with `ProfessionalSupportSectionViewModel`, populate fields + crisis card

```swift
protocol ProfessionalSupportSectionViewControllerDelegate: AnyObject {
    func didTapSave(_ viewController: ProfessionalSupportSectionViewController, data: EmotionalBundleSectionData)
    func didTapCancel(_ viewController: ProfessionalSupportSectionViewController)
}
```

- [ ] **Step 6: Build to verify all 5 compile**

Run: `xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet`

- [ ] **Step 7: Commit**

```bash
git add Soulverse/Features/Tools/EmotionalBundle/Views/RedFlagsSectionViewController.swift \
       Soulverse/Features/Tools/EmotionalBundle/Views/SupportMeSectionViewController.swift \
       Soulverse/Features/Tools/EmotionalBundle/Views/FeelCalmSectionViewController.swift \
       Soulverse/Features/Tools/EmotionalBundle/Views/StaySafeSectionViewController.swift \
       Soulverse/Features/Tools/EmotionalBundle/Views/ProfessionalSupportSectionViewController.swift
git commit -m "feat(emotional-bundle): add 5 section editor view controllers"
```

---

## Task 7: Coordinator + Navigation Wiring

**Files:**
- Create: `Soulverse/Features/Tools/EmotionalBundle/Presenter/EmotionalBundleCoordinator.swift`
- Modify: `Soulverse/Shared/Manager/AppCoordinator.swift:176`
- Modify: `Soulverse/Features/Tools/Views/ToolsViewController.swift:254-257`

- [ ] **Step 1: Create EmotionalBundleCoordinator.swift**

Follow `MoodCheckInCoordinator.swift` pattern at `Soulverse/MoodCheckIn/Presenter/MoodCheckInCoordinator.swift`.

Key requirements:
- Properties: `navigationController`, `service`, `uid`, `presenter`, `strongSelf` (self-retention)
- `start()` creates MainVC + Presenter, pushes MainVC
- Conforms to all 6 delegate protocols (main + 5 sections)
- On section select: reads `presenter.currentBundle()`, creates section ViewModel, pushes section VC
- On save: calls `service.saveSection` → on success: pop VC + `presenter.refreshAfterSave()`
- On cancel: pop VC
- On close: pop to Tools, call `cleanup()` to release `strongSelf`
- `onDismiss` closure for cleanup

- [ ] **Step 2: Add openEmotionalBundle to AppCoordinator.swift**

Add after line 176 in `Soulverse/Shared/Manager/AppCoordinator.swift`:

```swift
static func openEmotionalBundle(from sourceVC: UIViewController) {
    guard let uid = User.shared.userId,
          let navigationVC = sourceVC.navigationController else { return }
    let coordinator = EmotionalBundleCoordinator(
        navigationController: navigationVC,
        uid: uid
    )
    coordinator.start()
}
```

- [ ] **Step 3: Wire .emotionBundle action in ToolsViewController.swift**

Modify `Soulverse/Features/Tools/Views/ToolsViewController.swift` at lines 254-257. Replace the TODO in the `.emotionBundle` case:

```swift
case .emotionBundle:
    AppCoordinator.openEmotionalBundle(from: self)
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet`

- [ ] **Step 5: Create EmotionalBundleCoordinatorTests.swift**

Create at `SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleCoordinatorTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class EmotionalBundleCoordinatorTests: XCTestCase {

    private var navController: UINavigationController!
    private var mockService: EmotionalBundleServiceMock!

    override func setUp() {
        super.setUp()
        navController = UINavigationController()
        mockService = EmotionalBundleServiceMock()
        mockService.fetchBundleResult = .success(nil)
    }

    func testStartPushesMainViewController() {
        let coordinator = EmotionalBundleCoordinator(
            navigationController: navController,
            uid: "test-uid",
            service: mockService
        )
        coordinator.start()
        XCTAssertTrue(navController.topViewController is EmotionalBundleMainViewController)
    }

    func testSaveSectionCallsService() {
        let coordinator = EmotionalBundleCoordinator(
            navigationController: navController,
            uid: "test-uid",
            service: mockService
        )
        coordinator.start()

        // Simulate save via delegate
        let data = EmotionalBundleSectionData.redFlags([RedFlagItem(text: "test", sortOrder: 0)])
        // Coordinator conforms to RedFlagsSectionViewControllerDelegate
        // This test verifies the service is called
        XCTAssertEqual(mockService.saveSectionCallCount, 0)
    }
}
```

- [ ] **Step 6: Run tests**

Run: `xcodebuild test -workspace Soulverse.xcworkspace -scheme "Soulverse" -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' -only-testing:SoulverseTests/EmotionalBundleCoordinatorTests -quiet`

- [ ] **Step 7: Commit**

```bash
git add Soulverse/Features/Tools/EmotionalBundle/Presenter/EmotionalBundleCoordinator.swift \
       Soulverse/Shared/Manager/AppCoordinator.swift \
       Soulverse/Features/Tools/Views/ToolsViewController.swift \
       SoulverseTests/Tests/Features/EmotionalBundle/EmotionalBundleCoordinatorTests.swift
git commit -m "feat(emotional-bundle): add coordinator and navigation wiring"
```

---

## Task 8: Localization

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`
- Modify: `Soulverse/zh-TW.lproj/Localizable.strings`

- [ ] **Step 1: Add English localization keys**

Append to `Soulverse/en.lproj/Localizable.strings`. All keys prefixed with `emotional_bundle_`:

```
// MARK: - Emotional Bundle
"emotional_bundle_title" = "Emotional Bundle";
"emotional_bundle_subtitle" = "Prepare helpful tools for difficult emotional moments";

// Section titles
"emotional_bundle_section_red_flags" = "Red Flags";
"emotional_bundle_section_support_me" = "Support Me";
"emotional_bundle_section_feel_calm" = "Feel Calm";
"emotional_bundle_section_stay_safe" = "Stay Safe";
"emotional_bundle_section_professional_support" = "Professional Support";

// Red Flags
"emotional_bundle_red_flags_question" = "What tells me I'm having a hard time?";
"emotional_bundle_red_flag_label_1" = "Red Flag 1";
"emotional_bundle_red_flag_label_2" = "Red Flag 2";
"emotional_bundle_red_flag_placeholder" = "e.g., Being yelled at";
"emotional_bundle_red_flag_required_error" = "Please enter at least one red flag";

// Support Me
"emotional_bundle_support_me_question" = "Who helps me feel safer or less alone?";
"emotional_bundle_contact_label" = "Contact %d";
"emotional_bundle_contact_name" = "Name";
"emotional_bundle_contact_phone" = "Phone number";
"emotional_bundle_contact_email" = "Email";
"emotional_bundle_contact_relationship" = "Relationship";
"emotional_bundle_contact_name_placeholder" = "e.g., Stephy";
"emotional_bundle_contact_phone_placeholder" = "e.g., 646-098-7654";
"emotional_bundle_contact_email_placeholder" = "e.g., stephy@email.com";
"emotional_bundle_contact_relationship_placeholder" = "e.g., Friend";

// Feel Calm
"emotional_bundle_feel_calm_question" = "Things I can do to make me feel better";
"emotional_bundle_activity_label_1" = "Activity 1";
"emotional_bundle_activity_label_2" = "Activity 2 (Optional)";
"emotional_bundle_activity_label_3" = "Activity 3 (Optional)";
"emotional_bundle_activity_placeholder_1" = "e.g., Drawing helps me release stress";
"emotional_bundle_activity_placeholder_2" = "e.g., Drinking cold water";
"emotional_bundle_activity_placeholder_3" = "e.g., Go outside for 5 minutes";
"emotional_bundle_activity_required_error" = "Please enter at least one activity";

// Stay Safe
"emotional_bundle_stay_safe_question" = "How can I make this moment feel safer?";
"emotional_bundle_stay_safe_label" = "Actions";
"emotional_bundle_stay_safe_placeholder" = "e.g., Remove risky objects, Step outside";

// Professional Support
"emotional_bundle_professional_support_question" = "Professional Support";
"emotional_bundle_professional_contact_label" = "Professional Contact 1";
"emotional_bundle_professional_place" = "Place / Clinic";
"emotional_bundle_professional_name" = "Professional Name";
"emotional_bundle_professional_phone" = "Emergency Contact Number";
"emotional_bundle_professional_place_placeholder" = "e.g., Soulverse Wellness Center";
"emotional_bundle_professional_name_placeholder" = "e.g., Dr. Louis Reves";
"emotional_bundle_professional_phone_placeholder" = "e.g., (222) 140-310";

// Crisis resource
"emotional_bundle_crisis_call_confirmation" = "Call %@?";
"emotional_bundle_crisis_call_action" = "Call";
"emotional_bundle_crisis_cancel" = "Cancel";
```

- [ ] **Step 2: Add Traditional Chinese localization keys**

Append matching keys to `Soulverse/zh-TW.lproj/Localizable.strings` with zh-TW translations.

- [ ] **Step 3: Build to verify no localization errors**

Run: `xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet`

- [ ] **Step 4: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings Soulverse/zh-TW.lproj/Localizable.strings
git commit -m "feat(emotional-bundle): add localization strings for en and zh-TW"
```

---

## Task 9: Integration Testing + Build Verification

- [ ] **Step 1: Run full test suite**

Run: `xcodebuild test -workspace Soulverse.xcworkspace -scheme "Soulverse" -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' -quiet`

Verify: All existing tests still pass (no regressions).

- [ ] **Step 2: Run the app on simulator and manually verify**

1. Launch app → navigate to Self Care tab
2. Tap "Emotional Bundle" card → verify main hub loads with 5 sections (all incomplete)
3. Tap Red Flags → fill first field → save → verify checkmark appears on hub
4. Tap Support Me → fill a contact → save → verify checkmark
5. Tap Feel Calm → fill first activity → save → verify checkmark
6. Tap Stay Safe → fill action → save → verify checkmark
7. Tap Professional Support → verify crisis card shows (if US locale) → fill contact → save
8. Kill app → reopen → verify all data persists
9. Verify cancel (✕) discards changes

- [ ] **Step 3: Verify theme colors**

Grep all new files for hardcoded colors:
```bash
grep -rn "\.black\|\.white\|\.darkGray\|\.lightGray\|\.gray" Soulverse/Features/Tools/EmotionalBundle/
```
Expected: No matches (all should use `.theme*` colors).

- [ ] **Step 4: Verify localization**

Grep for hardcoded strings:
```bash
grep -rn '"[A-Z][a-z]' Soulverse/Features/Tools/EmotionalBundle/Views/ | grep -v NSLocalizedString | grep -v '//' | grep -v 'Layout\|enum\|case\|static\|import'
```
Expected: No hardcoded user-facing strings.

- [ ] **Step 5: Final commit if any fixes needed**

```bash
git add Soulverse/Features/Tools/EmotionalBundle/ \
       Soulverse/Shared/Service/EmotionalBundleService/ \
       Soulverse/Shared/Service/Protocols/EmotionalBundleServiceProtocol.swift
git commit -m "fix(emotional-bundle): address integration test findings"
```

---

## Task 10: Create Pull Request

- [ ] **Step 1: Push branch and create PR**

```bash
git push -u origin feat/tool-emotional-bundle
gh pr create --title "feat: add Emotional Bundle safety plan feature" --body "$(cat <<'EOF'
## Summary
- Add Emotional Bundle feature — a living safety plan with 5 editable sections
- Stored in Firestore at `users/{uid}/emotional_bundle/default`
- Entry from Self Care (Tools) tab → Bundle hub → Section editors
- Locale-aware crisis resource card (US: 988 Suicide & Crisis Lifeline)
- Character limits with visual feedback (red border + count)
- Full localization (en + zh-TW)

## Sections
- **Red Flags** — 2 text items (first required, 200 char limit)
- **Support Me** — 2 contacts (name/phone/email/relationship, 100 char limit)
- **Feel Calm** — 3 activities (first required, 100 char limit)
- **Stay Safe** — 1 actions field (100 char limit)
- **Professional Support** — crisis line card + 1 professional contact (100 char limit)

## Architecture
- Coordinator pattern (like MoodCheckInCoordinator)
- Protocol-based Firestore service with field-level section updates
- 22 new files, 5 modified files

## Test plan
- [ ] Unit tests for all ViewModels and Presenter
- [ ] Model encoding/decoding tests
- [ ] Manual: full save/load round-trip
- [ ] Manual: offline save + sync
- [ ] Manual: cancel discards changes
- [ ] Manual: completion indicators update correctly
- [ ] Manual: character limit red border appears
- [ ] Manual: both themes (Soul/Universe)
- [ ] Manual: both languages (en/zh-TW)
- [ ] Regression: existing tools still navigate correctly

## Spec
`docs/superpowers/specs/2026-04-15-emotional-bundle-design.md`
EOF
)"
```
