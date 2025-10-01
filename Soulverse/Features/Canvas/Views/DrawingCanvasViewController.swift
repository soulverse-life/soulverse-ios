//
//  CanvasViewController.swift
//

import UIKit
import PencilKit
import PhotosUI

class DrawingCanvasViewController: UIViewController {

    struct LaoutConstant {
        static let toolPickerHeight: CGFloat = 100
    }

    // MARK: - Properties
    var backgroundImage: UIImage?
    
    // MARK: - UI Elements
    private lazy var topBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(cancelDrawing), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("save", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(saveDrawing), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var toolbarStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(shareDrawing), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var undoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(undoAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var redoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.uturn.forward"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(redoAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    } ()
    

    private var canvasView: PKCanvasView!

    // MARK: - Properties
    private var toolPicker: PKToolPicker?
    private var customAddToolItem: Any?
    
    // MARK: - Recording Properties
    private var drawingSteps: [PKDrawing] = []
    private var isRecording = true
    private var isReplaying = false
    private var replayTimer: Timer?

    // MARK: - Initializers
    convenience init(backgroundImage: UIImage?) {
        self.init()
        self.backgroundImage = backgroundImage
    }

    // MARK: - Factory Methods
    static func createWithBackground(_ image: UIImage?) -> DrawingCanvasViewController {
        return DrawingCanvasViewController(backgroundImage: image)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupCanvas()
        setupToolPicker()
        setupBackgroundImage()
        startRecording()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupToolPickerPosition()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 隱藏工具選擇器避免影響其他頁面
        toolPicker?.setVisible(false, forFirstResponder: canvasView)

        // 移除觀察者
        if #available(iOS 18.0, *) {
            toolPicker?.removeObserver(self)
        }
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add top bar with Cancel/Save buttons
        view.addSubview(topBarView)
        topBarView.addSubview(cancelButton)
        topBarView.addSubview(saveButton)
        
        // Add toolbar stackview with Share/Undo/Redo buttons
        view.addSubview(toolbarStackView)
        toolbarStackView.addArrangedSubview(shareButton)
        toolbarStackView.addArrangedSubview(undoButton)
        toolbarStackView.addArrangedSubview(redoButton)
        
        // 創建背景圖片視圖
        view.addSubview(backgroundImageView)
        
        // 創建畫布
        canvasView = PKCanvasView()
        canvasView.isRulerActive = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Top bar with Cancel/Save buttons
        topBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ViewComponentConstants.navigationBarHeight)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        // Toolbar with Share/Undo/Redo buttons
        toolbarStackView.snp.makeConstraints { make in
            make.top.equalTo(topBarView.snp.bottom)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(ViewComponentConstants.smallActionButtonHeight)
        }
        
        shareButton.snp.makeConstraints { make in
            make.width.height.equalTo(ViewComponentConstants.smallActionButtonHeight)
        }
        
        undoButton.snp.makeConstraints { make in
            make.width.height.equalTo(ViewComponentConstants.smallActionButtonHeight)
        }
        
        redoButton.snp.makeConstraints { make in
            make.width.height.equalTo(ViewComponentConstants.smallActionButtonHeight)
        }
        
        // Canvas view takes remaining space
        canvasView.snp.makeConstraints { make in
            make.top.equalTo(toolbarStackView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 設置約束 - 居中並保持寬高比
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalTo(canvasView)
        }
    }
    
    private func setupCanvas() {
        // 設置畫布屬性
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        
        // 允許縮放和平移
        canvasView.minimumZoomScale = 0.5
        canvasView.maximumZoomScale = 3.0
        canvasView.bouncesZoom = true
    }
    
    private func setupToolPicker() {
        // 如果系統支援，設置自定義工具項
        if #available(iOS 18.0, *) {
            let items = PKToolPicker().toolItems
            toolPicker = PKToolPicker(toolItems: items)
        } else {
            toolPicker = PKToolPicker()
        }
        toolPicker?.colorUserInterfaceStyle = .light
        toolPicker?.showsDrawingPolicyControls = false
    }

    @available(iOS 18.0, *)
    private func getCustomAddTool() -> PKToolPickerCustomItem {
        var config = PKToolPickerCustomItem.Configuration(identifier: "com.soulverse.custom-add", name: "plus")

        // Provide a custom image for the custom tool item.
        config.imageProvider = { toolItem in
            guard let toolImage = UIImage(named: config.name) else {
                return UIImage()
            }
            return toolImage
        }

        return PKToolPickerCustomItem(configuration: config)
    }
    
    private func setupToolPickerPosition() {
        guard let toolPicker = toolPicker else { return }

        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)

        // 如果系統支援自定義工具，添加自己為觀察者
        if #available(iOS 18.0, *) {
            toolPicker.addObserver(self)
        }

        canvasView.becomeFirstResponder()

        if let tabBarHeight = tabBarController?.tabBar.frame.height {
            DispatchQueue.main.async {
                self.adjustCanvasInsets(tabBarHeight: tabBarHeight)
            }
        }
    }
    
    
    private func adjustCanvasInsets(tabBarHeight: CGFloat) {
        
        canvasView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: LaoutConstant.toolPickerHeight + 10,
            right: 0
        )
        
        canvasView.scrollIndicatorInsets = canvasView.contentInset
    }
    
    
    private func setupBackgroundImage() {

        // 使用傳入的背景圖片，如果沒有則使用默認圖片
        if let image = backgroundImage {
            backgroundImageView.image = image
        } else {
            backgroundImageView.image = UIImage(named: "emotion_jar")
        }
    }
    
    
    // MARK: - Actions
    
    @objc private func cancelDrawing() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func shareDrawing() {
        let image = renderDrawingAsImage()
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    @objc private func undoAction() {
        canvasView.undoManager?.undo()
    }
    
    @objc private func redoAction() {
        canvasView.undoManager?.redo()
    }
    
    @objc private func clearCanvas() {
        let alert = UIAlertController(title: "清除畫布", message: "確定要清除所有繪畫內容嗎？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確定", style: .destructive) { _ in
            self.canvasView.drawing = PKDrawing()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func addBackgroundImage() {
        let alert = UIAlertController(title: "選擇圖片", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "從相片選擇", style: .default) { _ in
            self.presentImagePicker()
        })
        
        alert.addAction(UIAlertAction(title: "移除背景", style: .destructive) { _ in
            self.backgroundImageView.image = nil
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func saveDrawing() {
        let image = renderDrawingAsImage()

        // Save image to Documents directory
        guard let fileName = saveImageToDocuments(image: image) else {
            showSaveErrorAlert()
            return
        }

        // Present result view directly without animation
        AppCoordinator.presentDrawingResult(imageFileName: fileName, from: self)
    }

    private func saveImageToDocuments(image: UIImage) -> String? {
        guard let data = image.pngData(),
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        // Generate filename with format: yyyyMMdd_HHmm.png
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmm"
        let fileName = "\(dateFormatter.string(from: Date())).png"

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            print("Image saved to: \(fileURL.path)")
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    private func showSaveErrorAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("save_failed", comment: "Save Failed"),
            message: NSLocalizedString("save_failed_message", comment: "Failed to save the drawing"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))
        present(alert, animated: true)
    }

    @available(iOS 18.0, *)
    private func handleCustomAddTool() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 添加圖片選項
        alert.addAction(UIAlertAction(title: NSLocalizedString("Add Photo", comment: ""), style: .default) { _ in
            self.presentImagePicker()
        })

        // 更改背景選項
        alert.addAction(UIAlertAction(title: NSLocalizedString("Change Background", comment: ""), style: .default) { _ in
            self.addBackgroundImage()
        })

        // 清除畫布選項
        alert.addAction(UIAlertAction(title: NSLocalizedString("Clear Canvas", comment: ""), style: .destructive) { _ in
            self.clearCanvas()
        })

        // 重播繪圖選項
        alert.addAction(UIAlertAction(title: NSLocalizedString("Replay Drawing", comment: ""), style: .default) { _ in
            self.startReplay()
        })

        // 取消選項
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        // 為 iPad 設置 popover
        if let popover = alert.popoverPresentationController {
            popover.sourceView = canvasView
            popover.sourceRect = CGRect(x: canvasView.bounds.midX, y: canvasView.bounds.maxY - 100, width: 0, height: 0)
        }

        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func presentImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func renderDrawingAsImage() -> UIImage {
        let bounds = canvasView.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)

        return renderer.image { context in
            // 繪製背景圖片
            if let backgroundImage = backgroundImageView.image {
                backgroundImage.draw(in: bounds)
            }

            // 繪製畫布內容
            canvasView.drawing.image(from: bounds, scale: UIScreen.main.scale).draw(in: bounds)
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(
            title: error == nil ? "保存成功" : "保存失敗",
            message: error?.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }

}

// MARK: - Recording Methods
extension DrawingCanvasViewController {
    
    private func startRecording() {
        drawingSteps = []
        isRecording = true
        // 記錄初始空白狀態
        drawingSteps.append(PKDrawing())
    }
    
    private func recordDrawingStep() {
        guard isRecording && !isReplaying else { return }
        
        // 深度複製當前繪畫狀態
        let currentDrawing = canvasView.drawing
        drawingSteps.append(currentDrawing)
        
        print("記錄步驟: \(drawingSteps.count)")
    }
    
    @objc private func startReplay() {
        guard !drawingSteps.isEmpty else { return }
        
        isReplaying = true
        
        // 清空畫布，開始重播
        canvasView.drawing = PKDrawing()
        
        var stepIndex = 0
        replayTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self = self, stepIndex < self.drawingSteps.count else {
                self?.finishReplay()
                timer.invalidate()
                return
            }
            
            // 顯示當前步驟
            self.canvasView.drawing = self.drawingSteps[stepIndex]
            
            stepIndex += 1
        }
    }
    
    private func finishReplay() {
        isReplaying = false
        replayTimer?.invalidate()
        replayTimer = nil
    }
}

extension DrawingCanvasViewController: CanvasViewPresenterDelegate {
    func didUpdate(viewModel: CanvasViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            
        }
    }
    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            
        }
    }
}

extension DrawingCanvasViewController: PKCanvasViewDelegate {
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // 繪畫內容改變時的回調
        
        recordDrawingStep()
    }
    
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        // 開始使用工具時的回調
    }
    
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        // 結束使用工具時的回調
        recordDrawingStep()
    }
}

@available(iOS 18.0, *)
extension DrawingCanvasViewController: PKToolPickerObserver {

    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        // 檢查是否選擇了我們的自定義工具
        if let selectedTool = toolPicker.selectedTool as? PKToolPickerCustomItem,
           selectedTool.identifier == "com.soulverse.add-tool" {
            handleCustomAddTool()
        }
    }
}

extension DrawingCanvasViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let image = object as? UIImage {
                    self?.backgroundImageView.image = image
                }
            }
        }
    }
}
