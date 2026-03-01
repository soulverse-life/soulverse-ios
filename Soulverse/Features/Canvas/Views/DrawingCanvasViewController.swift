//
//  CanvasViewController.swift
//

import UIKit
import PencilKit
import PhotosUI

class DrawingCanvasViewController: UIViewController {

    struct LayoutConstant {
        static let toolPickerHeight: CGFloat = 100
        static let backgroundImageInset: CGFloat = 40
    }

    // MARK: - Properties
    var backgroundImage: UIImage?
    var checkinId: String?
    var promptUsed: String?
    var templateName: String?
    private lazy var presenter: DrawingCanvasPresenterType = {
        let presenter = DrawingCanvasPresenter()
        presenter.delegate = self
        return presenter
    }()

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
        button.titleLabel?.font = UIFont.projectFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(cancelDrawing), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("save", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.projectFont(ofSize: 17, weight: .semibold)
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

    private lazy var toolPickerToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil.tip"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(toggleToolPicker), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var loadingOverlay: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.isHidden = true
        overlay.addSubview(loadingView)

        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return overlay
    }()

    private let loadingView = LoadingView()

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = true
        return imageView
    } ()
    

    private var canvasView: PKCanvasView!

    // MARK: - Properties
    private var toolPicker: PKToolPicker?
    private var isToolPickerVisible: Bool = true
    
    // MARK: - Recording Properties
    private var drawingSteps: [PKDrawing] = []
    private var isRecording = true
    private var isReplaying = false
    private var replayTimer: Timer?

    // MARK: - Layout Properties
    private var hasConfiguredInitialLayout = false
    private var canvasContentSize: CGSize = .zero
    private var initialZoomScale: CGFloat = 1.0

    // MARK: - Initializers
    convenience init(backgroundImage: UIImage?, checkinId: String? = nil, promptUsed: String? = nil) {
        self.init()
        self.backgroundImage = backgroundImage
        self.checkinId = checkinId
        self.promptUsed = promptUsed
    }

    // MARK: - Factory Methods
    static func createWithBackground(_ image: UIImage?, checkinId: String? = nil, promptUsed: String? = nil) -> DrawingCanvasViewController {
        return DrawingCanvasViewController(backgroundImage: image, checkinId: checkinId, promptUsed: promptUsed)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 確保 background image frame 已設置（但不設置 zoom）
        if !hasConfiguredInitialLayout && canvasView.bounds.width > 0 {
            setupInitialBackgroundFrame()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupToolPickerPosition()

        if !hasConfiguredInitialLayout {
            configureBackgroundImageLayout()
            hasConfiguredInitialLayout = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        toolPicker?.setVisible(false, forFirstResponder: canvasView)
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

        // Add toolbar stackview with Share/Undo/Redo/ToolPicker buttons
        view.addSubview(toolbarStackView)
        toolbarStackView.addArrangedSubview(shareButton)
        toolbarStackView.addArrangedSubview(undoButton)
        toolbarStackView.addArrangedSubview(redoButton)
        toolbarStackView.addArrangedSubview(toolPickerToggleButton)

        // 創建畫布
        canvasView = PKCanvasView()
        canvasView.isRulerActive = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .gray
        view.addSubview(canvasView)
        view.addSubview(loadingOverlay)

        // 創建背景圖片視圖 - 添加為 canvasView 的子視圖以支持縮放
        canvasView.addSubview(backgroundImageView)
        canvasView.sendSubviewToBack(backgroundImageView)

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

        toolPickerToggleButton.snp.makeConstraints { make in
            make.width.height.equalTo(ViewComponentConstants.smallActionButtonHeight)
        }

        // Canvas view takes remaining space
        canvasView.snp.makeConstraints { make in
            make.top.equalTo(toolbarStackView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        loadingOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupCanvas() {
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.bouncesZoom = false

        canvasView.showsVerticalScrollIndicator = false
        canvasView.showsHorizontalScrollIndicator = false

    }
    
    private func setupToolPicker() {
        toolPicker = PKToolPicker()
        toolPicker?.colorUserInterfaceStyle = .light
        toolPicker?.showsDrawingPolicyControls = false
    }

    private func setupToolPickerPosition() {
        guard let toolPicker = toolPicker else { return }

        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)

        canvasView.becomeFirstResponder()

        if let tabBarHeight = tabBarController?.tabBar.frame.height {
            DispatchQueue.main.async {
                self.adjustCanvasInsets(tabBarHeight: tabBarHeight)
            }
        }
    }
    
    
    private func adjustCanvasInsets(tabBarHeight: CGFloat) {
        // 先更新背景圖片 frame（會設置基本的 contentInset）
        updateBackgroundFrame()

        // 然後調整底部 inset 為工具選擇器留出空間
        let toolPickerBottomInset = LayoutConstant.toolPickerHeight + 10
        var currentInsets = canvasView.contentInset
        currentInsets.bottom = max(currentInsets.bottom, toolPickerBottomInset)

        canvasView.contentInset = currentInsets
        canvasView.scrollIndicatorInsets = currentInsets
    }
    
    
    private func setupBackgroundImage() {
        // 使用傳入的背景圖片，如果沒有則使用默認圖片
        if let image = backgroundImage {
            backgroundImageView.image = image
        } else {
            backgroundImageView.image = UIImage(named: "emotion_jar")
        }
        // 佈局配置會在 viewDidAppear 中進行
    }

    private func setupInitialBackgroundFrame() {
        guard let image = backgroundImageView.image else { return }

        let imageSize = image.size
        canvasContentSize = imageSize

        // 只設置 canvas contentSize，不設置 backgroundImageView.frame
        // frame 會在 configureBackgroundImageLayout() 中正確設置
        canvasView.contentSize = imageSize
    }

    private func configureBackgroundImageLayout() {
        guard canvasContentSize != .zero else { return }

        let imageSize = canvasContentSize
        let canvasBounds = canvasView.bounds.size

        // 計算初始縮放比例，使圖片適配屏幕（scaleAspectFit）
        let widthScale = canvasBounds.width / imageSize.width
        let heightScale = canvasBounds.height / imageSize.height
        initialZoomScale = min(widthScale, heightScale)

        // 設置 PKCanvasView 的縮放範圍和初始縮放
        // 最小縮放 = 初始縮放（不能比適配屏幕的尺寸更小）
        canvasView.minimumZoomScale = initialZoomScale
        canvasView.maximumZoomScale = initialZoomScale * 3.0
        canvasView.zoomScale = initialZoomScale

        // 設置背景圖片為縮放後的尺寸
        updateBackgroundFrame()

        #if DEBUG
            print("Canvas setup - imageSize: \(imageSize), initialScale: \(initialZoomScale), zoomScale: \(canvasView.zoomScale)")
        #endif
    }

    private func updateBackgroundFrame() {
        let imageSize = canvasContentSize
        let canvasBounds = canvasView.bounds.size
        let currentZoom = canvasView.zoomScale
        let inset = LayoutConstant.backgroundImageInset

        // 計算當前縮放下的圖片尺寸（扣除 inset）
        let scaledWidth = imageSize.width * currentZoom
        let scaledHeight = imageSize.height * currentZoom

        // 背景圖片位置加上 inset 偏移
        backgroundImageView.frame = CGRect(
            x: inset,
            y: inset,
            width: scaledWidth - (inset * 2),
            height: scaledHeight - (inset * 2)
        )

        // 更新 contentSize 以匹配縮放後的尺寸（包含 inset）
        canvasView.contentSize = CGSize(width: scaledWidth, height: scaledHeight)

        // 使用 contentInset 來居中內容（當內容小於 bounds 時）
        let horizontalInset = max((canvasBounds.width - scaledWidth) / 2, 0)
        let verticalInset = max((canvasBounds.height - scaledHeight) / 2, 0)

        canvasView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
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

    @objc private func toggleToolPicker() {
        isToolPickerVisible.toggle()

        if isToolPickerVisible {
            // Show tool picker and enable drawing
            toolPicker?.setVisible(true, forFirstResponder: canvasView)
            canvasView.becomeFirstResponder()
            canvasView.drawingPolicy = .anyInput
            toolPickerToggleButton.setImage(UIImage(systemName: "pencil.tip"), for: .normal)
        } else {
            // Hide tool picker and enable pan mode
            toolPicker?.setVisible(false, forFirstResponder: canvasView)
            canvasView.resignFirstResponder()
            canvasView.drawingPolicy = .pencilOnly
            toolPickerToggleButton.setImage(UIImage(systemName: "hand.draw"), for: .normal)
        }
    }

    @objc private func clearCanvas() {
        let alert = UIAlertController(title: "清除畫布", message: "確定要清除所有繪畫內容嗎？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確定", style: .destructive) { _ in
            self.canvasView.drawing = PKDrawing()
        })
        
        present(alert, animated: true)
    }
    
    
    @objc private func saveDrawing() {
        let image = renderDrawingAsImage()
        let recordingData = canvasView.drawing.dataRepresentation()

        presenter.submitDrawing(
            image: image,
            recordingData: recordingData,
            checkinId: checkinId,
            promptUsed: promptUsed,
            templateName: templateName
        )
    }

    
    // MARK: - Helper Methods
    private func renderDrawingAsImage() -> UIImage {
        // 渲染整個 canvas 內容（完整的背景圖片尺寸 + 所有繪圖）
        // 不考慮當前縮放或可見區域

        let renderSize = canvasContentSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale

        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)

        return renderer.image { context in
            // 繪製背景圖片（完整尺寸）
            if let backgroundImage = backgroundImageView.image {
                backgroundImage.draw(in: CGRect(origin: .zero, size: renderSize))
            }

            // 繪製畫布內容（完整尺寸）
            // 從整個 canvas 內容區域提取繪圖
            let drawing = canvasView.drawing
            let drawingRect = CGRect(origin: .zero, size: renderSize)
            let drawingImage = drawing.image(from: drawingRect, scale: UIScreen.main.scale)
            drawingImage.draw(in: drawingRect)
        }
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

        let currentDrawing = canvasView.drawing
        drawingSteps.append(currentDrawing)
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

// MARK: - UIScrollViewDelegate
extension DrawingCanvasViewController: UIScrollViewDelegate {

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 當 canvas 縮放時，更新背景圖片的 frame
        updateBackgroundFrame()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 當 canvas 滾動時，更新背景圖片的位置
        updateBackgroundFrame()
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
                    // 重新配置背景圖片佈局以適應新圖片
                    self?.hasConfiguredInitialLayout = false
                    self?.configureBackgroundImageLayout()
                }
            }
        }
    }
}

// MARK: - DrawingCanvasPresenterDelegate
extension DrawingCanvasViewController: DrawingCanvasPresenterDelegate {

    func didStartSavingDrawing() {
        loadingOverlay.isHidden = false
        loadingView.startAnimating()
        saveButton.isEnabled = false
    }

    func didFinishSavingDrawing(image: UIImage) {
        loadingView.stopAnimating()
        loadingOverlay.isHidden = true
        saveButton.isEnabled = true
        AppCoordinator.presentDrawingResult(image: image, from: self)
    }

    func didFailSavingDrawing(error: Error) {
        loadingView.stopAnimating()
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
