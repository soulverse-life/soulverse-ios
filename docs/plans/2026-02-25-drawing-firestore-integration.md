# Drawing-to-Firestore Integration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire up the drawing save flow so that when a user finishes drawing and taps Save, the image and PKDrawing recording data are uploaded to Firebase Storage and persisted to Firestore — then navigate to the result view.

**Architecture:** A new dedicated `DrawingCanvasPresenter` owns the save logic following the VIPER pattern. The view controller delegates to the presenter, which calls `FirestoreDrawingService.submitDrawing()`. The presenter notifies the view via delegate callbacks for loading/success/failure states. The `checkinId` is threaded from `MoodCheckInCoordinator` through `AppCoordinator` to the drawing canvas.

**Tech Stack:** Swift, UIKit, PencilKit, Firebase Firestore, Firebase Storage, SnapKit

---

### Task 1: Create DrawingCanvasPresenter with protocol definitions

**Files:**
- Create: `Soulverse/Features/Canvas/Presenter/DrawingCanvasPresenter.swift`

**Step 1: Create the presenter file with protocols and implementation**

```swift
//
//  DrawingCanvasPresenter.swift
//  Soulverse
//

import UIKit

// MARK: - Delegate Protocol

protocol DrawingCanvasPresenterDelegate: AnyObject {
    func didStartSavingDrawing()
    func didFinishSavingDrawing(image: UIImage)
    func didFailSavingDrawing(error: Error)
}

// MARK: - Presenter Protocol

protocol DrawingCanvasPresenterType: AnyObject {
    var delegate: DrawingCanvasPresenterDelegate? { get set }
    func submitDrawing(
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        isFromCheckIn: Bool,
        promptUsed: String?
    )
}

// MARK: - Implementation

final class DrawingCanvasPresenter: DrawingCanvasPresenterType {

    weak var delegate: DrawingCanvasPresenterDelegate?

    private var isSaving = false

    func submitDrawing(
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        isFromCheckIn: Bool,
        promptUsed: String?
    ) {
        guard !isSaving else { return }
        guard let uid = User.shared.userId else {
            delegate?.didFailSavingDrawing(
                error: NSError(domain: "DrawingCanvasPresenter",
                               code: -1,
                               userInfo: [NSLocalizedDescriptionKey:
                                   NSLocalizedString("drawing_save_not_logged_in",
                                                     comment: "Error when user is not logged in")])
            )
            return
        }

        isSaving = true
        delegate?.didStartSavingDrawing()

        FirestoreDrawingService.submitDrawing(
            uid: uid,
            image: image,
            recordingData: recordingData,
            checkinId: checkinId,
            isFromCheckIn: isFromCheckIn,
            promptUsed: promptUsed
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSaving = false

                switch result {
                case .success:
                    self.delegate?.didFinishSavingDrawing(image: image)
                case .failure(let error):
                    self.delegate?.didFailSavingDrawing(error: error)
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add Soulverse/Features/Canvas/Presenter/DrawingCanvasPresenter.swift
git commit -m "feat: add DrawingCanvasPresenter for Firestore drawing submission"
```

---

### Task 2: Update DrawingCanvasViewController to use the presenter

**Files:**
- Modify: `Soulverse/Features/Canvas/Views/DrawingCanvasViewController.swift`

**Step 1: Add new properties for presenter, checkinId, and promptUsed**

Add these properties to `DrawingCanvasViewController` (after the existing `backgroundImage` property at line 17):

```swift
var checkinId: String?
var promptUsed: String?
private lazy var presenter: DrawingCanvasPresenterType = {
    let presenter = DrawingCanvasPresenter()
    presenter.delegate = self
    return presenter
}()
```

**Step 2: Add loading overlay UI**

Add a loading overlay property (after the `toolPickerToggleButton` at line 91):

```swift
private lazy var loadingOverlay: UIView = {
    let overlay = UIView()
    overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    overlay.isHidden = true

    let spinner = UIActivityIndicatorView(style: .large)
    spinner.color = .white
    spinner.tag = 100
    spinner.startAnimating()
    overlay.addSubview(spinner)

    spinner.snp.makeConstraints { make in
        make.center.equalToSuperview()
    }
    return overlay
}()
```

Add `loadingOverlay` to the view hierarchy in `setupUI()` — after `view.addSubview(canvasView)` (line 189):

```swift
view.addSubview(loadingOverlay)
```

Add constraints in `setupConstraints()` — at the end of the method:

```swift
loadingOverlay.snp.makeConstraints { make in
    make.edges.equalToSuperview()
}
```

**Step 3: Update `saveDrawing()` to go through the presenter**

Replace the existing `saveDrawing()` method (lines 424-429) with:

```swift
@objc private func saveDrawing() {
    let image = renderDrawingAsImage()
    let recordingData = canvasView.drawing.dataRepresentation()
    let isFromCheckIn = checkinId != nil

    presenter.submitDrawing(
        image: image,
        recordingData: recordingData,
        checkinId: checkinId,
        isFromCheckIn: isFromCheckIn,
        promptUsed: promptUsed
    )
}
```

**Step 4: Implement DrawingCanvasPresenterDelegate**

Add a new extension at the bottom of the file:

```swift
// MARK: - DrawingCanvasPresenterDelegate
extension DrawingCanvasViewController: DrawingCanvasPresenterDelegate {

    func didStartSavingDrawing() {
        loadingOverlay.isHidden = false
        saveButton.isEnabled = false
    }

    func didFinishSavingDrawing(image: UIImage) {
        loadingOverlay.isHidden = true
        saveButton.isEnabled = true
        AppCoordinator.presentDrawingResult(image: image, from: self)
    }

    func didFailSavingDrawing(error: Error) {
        loadingOverlay.isHidden = true
        saveButton.isEnabled = true

        let alert = UIAlertController(
            title: NSLocalizedString("drawing_save_error_title", comment: "Save error title"),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: "OK"),
            style: .default
        ))
        present(alert, animated: true)
    }
}
```

**Step 5: Update the convenience init and factory method to accept new params**

Replace the existing convenience init (line 120-123) and factory method (line 126-128):

```swift
convenience init(backgroundImage: UIImage?, checkinId: String? = nil, promptUsed: String? = nil) {
    self.init()
    self.backgroundImage = backgroundImage
    self.checkinId = checkinId
    self.promptUsed = promptUsed
}

static func createWithBackground(_ image: UIImage?, checkinId: String? = nil, promptUsed: String? = nil) -> DrawingCanvasViewController {
    return DrawingCanvasViewController(backgroundImage: image, checkinId: checkinId, promptUsed: promptUsed)
}
```

**Step 6: Commit**

```bash
git add Soulverse/Features/Canvas/Views/DrawingCanvasViewController.swift
git commit -m "feat: wire DrawingCanvasViewController to presenter for Firestore save"
```

---

### Task 3: Thread checkinId through AppCoordinator

**Files:**
- Modify: `Soulverse/Shared/Manager/AppCoordinator.swift` (lines 81-96, 131-139)

**Step 1: Add checkinId parameter to openDrawingCanvas()**

Replace the `openDrawingCanvas` method (lines 81-96):

```swift
static func openDrawingCanvas(from sourceVC: UIViewController, prompt: CanvasPrompt? = nil, checkinId: String? = nil) {
    let drawingCanvasVC = DrawingCanvasViewController()
    drawingCanvasVC.hidesBottomBarWhenPushed = true
    drawingCanvasVC.checkinId = checkinId
    drawingCanvasVC.promptUsed = prompt?.artTherapyPrompt

    // Set background image from prompt's template if available
    if let templateImage = prompt?.templateImage {
        drawingCanvasVC.backgroundImage = templateImage
    }

    guard let navigationVC = sourceVC.navigationController else {
        sourceVC.show(drawingCanvasVC, sender: nil)
        return
    }

    navigationVC.pushViewController(drawingCanvasVC, animated: true)
}
```

**Step 2: Pass checkinId in the mood check-in completion handler**

Update the `onComplete` closure (line 131-145). The `MoodCheckInCoordinator` needs to expose `lastSubmittedCheckinId` in the callback. Since the coordinator property is already `private(set)`, we capture the coordinator in the closure.

Replace the `coordinator.onComplete` block:

```swift
coordinator.onComplete = { [weak sourceVC, weak coordinator] data, selectedAction in
    let checkinId = coordinator?.lastSubmittedCheckinId

    sourceVC?.dismiss(animated: true) {
        completion?(true, data)

        // Handle post-dismiss action
        guard let sourceVC = sourceVC else { return }
        switch selectedAction {
        case .draw:
            AppCoordinator.openDrawingCanvas(from: sourceVC, checkinId: checkinId)
        case .writeJournal:
            print("TODO: Write Journal action")
        case .none:
            break
        }
    }
}
```

**Step 3: Commit**

```bash
git add Soulverse/Shared/Manager/AppCoordinator.swift
git commit -m "feat: thread checkinId from mood check-in to drawing canvas"
```

---

### Task 4: Add localization strings

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`
- Modify: `Soulverse/zh-TW.lproj/Localizable.strings`

**Step 1: Add English strings**

Append to `en.lproj/Localizable.strings`:

```
// Drawing Save
"drawing_save_error_title" = "Save Failed";
"drawing_save_not_logged_in" = "Please log in to save your drawing.";
```

**Step 2: Add Traditional Chinese strings**

Append to `zh-TW.lproj/Localizable.strings`:

```
// Drawing Save
"drawing_save_error_title" = "儲存失敗";
"drawing_save_not_logged_in" = "請先登入以儲存你的畫作。";
```

**Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings Soulverse/zh-TW.lproj/Localizable.strings
git commit -m "feat: add localization strings for drawing save errors"
```

---

### Task 5: Build verification

**Step 1: Build the project to verify no compilation errors**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: BUILD SUCCEEDED

**Step 2: Fix any compilation errors if they exist**

**Step 3: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: resolve build issues from drawing Firestore integration"
```
