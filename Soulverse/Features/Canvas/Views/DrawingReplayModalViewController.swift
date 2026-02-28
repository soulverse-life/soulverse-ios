//
//  DrawingReplayModalViewController.swift
//  Soulverse
//

import UIKit
import PencilKit
import SnapKit

final class DrawingReplayModalViewController: UIViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardWidthRatio: CGFloat = 0.8
        static let cardCornerRadius: CGFloat = 16
        static let closeButtonSize: CGFloat = 32
        static let closeButtonInset: CGFloat = 12
        static let dimmingAlpha: CGFloat = 0.5
        static let canvasPadding: CGFloat = 16
    }

    // MARK: - Properties

    private let drawing: DrawingModel
    private let presenter: DrawingReplayPresenterType
    private var allStrokes: [PKStroke] = []
    private var drawingBounds: CGRect = .zero
    private var replayTransform: CGAffineTransform = .identity
    private var isLoadingComplete: Bool = false
    private var hasStartedReplay: Bool = false

    // MARK: - UI Components

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(Layout.dimmingAlpha)
        view.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissModal))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Layout.cardCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var templateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.isUserInteractionEnabled = false
        canvas.drawingPolicy = .pencilOnly
        canvas.backgroundColor = .white
        canvas.isOpaque = true
        return canvas
    }()

    private lazy var loadingView: LoadingView = {
        let view = LoadingView()
        return view
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .themeTextSecondary
        button.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        button.layer.cornerRadius = Layout.closeButtonSize / 2
        button.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    init(drawing: DrawingModel, presenter: DrawingReplayPresenterType = DrawingReplayPresenter()) {
        self.drawing = drawing
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        self.presenter.delegate = self
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureTemplateBackground()
        presenter.loadRecording(from: drawing.recordingURL)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.2) {
            self.dimmingView.alpha = 1
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startReplayIfReady()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(dimmingView)
        view.addSubview(cardView)
        cardView.addSubview(templateImageView)
        cardView.addSubview(canvasView)
        cardView.addSubview(loadingView)
        cardView.addSubview(closeButton)
    }

    private func setupConstraints() {
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(Layout.cardWidthRatio)
            make.height.equalTo(cardView.snp.width)
        }

        templateImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        canvasView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.closeButtonInset)
            make.trailing.equalToSuperview().offset(-Layout.closeButtonInset)
            make.size.equalTo(Layout.closeButtonSize)
        }
    }

    private func configureTemplateBackground() {
        guard let name = drawing.templateName else { return }
        guard let image = UIImage(named: name) else {
            #if DEBUG
            print("[DrawingReplay] Template image not found in asset catalog: \"\(name)\"")
            #endif
            return
        }
        templateImageView.image = image
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
    }

    // MARK: - Replay Start

    private func startReplayIfReady() {
        guard isLoadingComplete, !hasStartedReplay else { return }
        let canvasSize = canvasView.bounds.size
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }

        hasStartedReplay = true
        replayTransform = calculateTransform(drawingBounds: drawingBounds, canvasSize: canvasSize)
        presenter.startReplay(strokes: allStrokes, transform: replayTransform)
    }

    // MARK: - Transform Calculation

    private func calculateTransform(drawingBounds: CGRect, canvasSize: CGSize) -> CGAffineTransform {
        guard drawingBounds.width > 0, drawingBounds.height > 0,
              canvasSize.width > 0, canvasSize.height > 0 else {
            return .identity
        }

        let padding = Layout.canvasPadding
        let availableWidth = canvasSize.width - padding * 2
        let availableHeight = canvasSize.height - padding * 2

        let scaleX = availableWidth / drawingBounds.width
        let scaleY = availableHeight / drawingBounds.height
        let scale = min(scaleX, scaleY)

        let scaledWidth = drawingBounds.width * scale
        let scaledHeight = drawingBounds.height * scale
        let offsetX = (canvasSize.width - scaledWidth) / 2 - drawingBounds.origin.x * scale
        let offsetY = (canvasSize.height - scaledHeight) / 2 - drawingBounds.origin.y * scale

        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: offsetX, ty: offsetY)
    }

    // MARK: - Actions

    @objc private func dismissModal() {
        presenter.stopReplay()
        UIView.animate(withDuration: 0.2, animations: {
            self.dimmingView.alpha = 0
            self.cardView.alpha = 0
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

// MARK: - DrawingReplayPresenterDelegate

extension DrawingReplayModalViewController: DrawingReplayPresenterDelegate {

    func didStartLoading() {
        loadingView.startAnimating()
    }

    func didFinishLoading(strokes: [PKStroke], bounds: CGRect) {
        loadingView.stopAnimating()
        allStrokes = strokes
        drawingBounds = bounds
        isLoadingComplete = true

        startReplayIfReady()
    }

    func didFailLoading(error: Error) {
        loadingView.stopAnimating()
        let message = NSLocalizedString("drawing_replay_error", comment: "Unable to load drawing")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: "OK"),
            style: .default
        ) { [weak self] _ in
            self?.dismissModal()
        })
        present(alert, animated: true)
    }

    func didReplayStroke(drawing: PKDrawing) {
        canvasView.drawing = drawing
    }

    func didFinishReplay() {
        // Loop: restart after a brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, !self.allStrokes.isEmpty else { return }
            self.canvasView.drawing = PKDrawing()
            self.presenter.startReplay(
                strokes: self.allStrokes,
                transform: self.replayTransform
            )
        }
    }
}
