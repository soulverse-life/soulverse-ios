//
//  CheckInDetailViewController.swift
//  Soulverse
//
//  Detail page showing a single mood check-in with planet, drawing,
//  and journal sections. Supports arrow/swipe navigation between
//  multiple check-ins from the same day.
//

import SnapKit
import UIKit

final class CheckInDetailViewController: ViewController {

    // MARK: - Properties

    private var presenter: CheckInDetailPresenterType
    private var currentViewModel: CheckInDetailViewModel?

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("checkin_detail_title", comment: ""),
            showBackButton: true
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private let dateLabelView: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private let planetView = DetailPlanetView()

    private let emotionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: CheckInDetailLayout.emotionLabelFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private let tagsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = CheckInDetailLayout.tagsInterCardSpacing
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()

    private let intensityTagView = IntensityTagView()
    private let dimensionTagView = DimensionTagView()

    private let drawingSection = DetailDrawingSection()
    private let reflectionSection = DetailReflectionSection()
    private let journalSection = DetailJournalSection()

    /// Vertical stack so hidden sections collapse from layout (UIStackView respects isHidden).
    private let sectionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = CheckInDetailLayout.sectionSpacing
        return stack
    }()

    private lazy var leftArrowButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = .themeTextPrimary
        button.isHidden = true
        button.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        return button
    }()

    private lazy var rightArrowButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = .themeTextPrimary
        button.isHidden = true
        button.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    init(checkIns: [MoodCheckInModel], initialIndex: Int = 0) {
        self.presenter = CheckInDetailPresenter(checkIns: checkIns, initialIndex: initialIndex)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()

        presenter.delegate = self
        presenter.loadCurrentCheckIn()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleDataChanged),
            name: NSNotification.Name(Notification.DrawingDidChange), object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(navigationView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(planetView)
        contentView.addSubview(emotionLabel)

        tagsStack.addArrangedSubview(intensityTagView)
        tagsStack.addArrangedSubview(dimensionTagView)
        contentView.addSubview(tagsStack)

        sectionsStack.addArrangedSubview(drawingSection)
        sectionsStack.addArrangedSubview(reflectionSection)
        sectionsStack.addArrangedSubview(journalSection)
        contentView.addSubview(sectionsStack)

        view.addSubview(leftArrowButton)
        view.addSubview(rightArrowButton)

        drawingSection.delegate = self
        reflectionSection.delegate = self
        journalSection.delegate = self

        // Add date label as right content in navigation
        navigationView.addRightContent(dateLabelView)

        setupConstraints()
    }

    private func setupConstraints() {
        let horizontalPadding = CheckInDetailLayout.sectionHorizontalPadding

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        planetView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CheckInDetailLayout.planetTopPadding)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(CheckInDetailLayout.planetGlowDiameter)
        }

        emotionLabel.snp.makeConstraints { make in
            make.top.equalTo(planetView.snp.bottom).offset(CheckInDetailLayout.emotionLabelTopPadding)
            make.centerX.equalToSuperview()
        }

        tagsStack.snp.makeConstraints { make in
            make.top.equalTo(emotionLabel.snp.bottom).offset(CheckInDetailLayout.tagsTopPadding)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        sectionsStack.snp.makeConstraints { make in
            make.top.equalTo(tagsStack.snp.bottom).offset(CheckInDetailLayout.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
            make.bottom.equalToSuperview().offset(-CheckInDetailLayout.contentBottomPadding)
        }

        let arrowSize = CheckInDetailLayout.arrowButtonSize
        let arrowInset = CheckInDetailLayout.arrowButtonHorizontalInset

        leftArrowButton.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(arrowInset)
            make.centerY.equalTo(planetView)
            make.width.height.equalTo(arrowSize)
        }

        rightArrowButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-arrowInset)
            make.centerY.equalTo(planetView)
            make.width.height.equalTo(arrowSize)
        }
    }

    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextTapped))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(previousTapped))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    // MARK: - Actions

    @objc private func previousTapped() {
        presenter.goToPrevious()
    }

    @objc private func nextTapped() {
        presenter.goToNext()
    }

    @objc private func handleDataChanged() {
        presenter.loadCurrentCheckIn()
    }
}

// MARK: - CheckInDetailPresenterDelegate

extension CheckInDetailViewController: CheckInDetailPresenterDelegate {
    func didUpdateViewModel(_ viewModel: CheckInDetailViewModel) {
        currentViewModel = viewModel

        if viewModel.isLoadingContent {
            // Phase 1: render mandatory sections + show loading spinners
            dateLabelView.text = viewModel.dateText
            planetView.configure(colorHex: viewModel.colorHex, intensity: viewModel.colorIntensity)
            emotionLabel.text = viewModel.emotionName

            intensityTagView.configure(
                level: viewModel.intensityLevel,
                totalLevels: ColorIntensityConstants.levelCount,
                color: UIColor(hex: viewModel.colorHex) ?? .themeTextSecondary
            )
            dimensionTagView.configure(
                topicLabel: viewModel.topicLabel,
                topicColor: Topic(rawValue: viewModel.topicRawValue)?.mainColor ?? .themeTextSecondary
            )

            leftArrowButton.isHidden = !viewModel.canGoBack
            rightArrowButton.isHidden = !viewModel.canGoForward

            drawingSection.showLoading()
            reflectionSection.showLoading()
            reflectionSection.isHidden = false
            journalSection.showLoading()
            scrollView.setContentOffset(.zero, animated: false)
        } else {
            // Phase 2: only update drawing/reflection/journal sections
            drawingSection.configure(
                imageURL: viewModel.drawingImageURL,
                checkinId: viewModel.checkinId
            )
            // Reflection section is only meaningful when a drawing exists.
            let hasDrawing = viewModel.drawingImageURL != nil
            reflectionSection.isHidden = !hasDrawing
            if hasDrawing {
                reflectionSection.configure(
                    drawingId: viewModel.drawingId,
                    imageURL: viewModel.drawingImageURL,
                    reflectiveQuestion: viewModel.reflectiveQuestion,
                    reflectiveAnswer: viewModel.reflectiveAnswer,
                    checkinId: viewModel.checkinId
                )
            }
            journalSection.configure(
                title: viewModel.journalTitle,
                content: viewModel.journalContent,
                checkinId: viewModel.checkinId
            )
        }
    }
}

// MARK: - Section Delegates

extension CheckInDetailViewController: DetailDrawingSectionDelegate {
    func detailDrawingSectionDidTapCreate(_ section: DetailDrawingSection, checkinId: String?) {
        AppCoordinator.presentDrawingPrompt(
            from: self,
            checkinId: checkinId,
            recordedEmotion: currentViewModel?.recordedEmotion
        )
    }
}

extension CheckInDetailViewController: DetailReflectionSectionDelegate {
    func detailReflectionSectionDidTapAdd(
        _ section: DetailReflectionSection,
        drawingId: String,
        imageURL: String?,
        reflectiveQuestion: String?,
        reflectiveAnswer: String?
    ) {
        let resolvedQuestion = reflectiveQuestion
            ?? NSLocalizedString("drawing_reflection_generic_question", comment: "")
        let viewModel = DrawingReflectionViewModel(
            drawingId: drawingId,
            drawingImage: nil,
            drawingImageURL: imageURL,
            reflectiveQuestion: resolvedQuestion,
            reflectiveAnswer: reflectiveAnswer
        )
        AppCoordinator.presentDrawingReflection(viewModel: viewModel, from: self)
    }
}

extension CheckInDetailViewController: DetailJournalSectionDelegate {
    func detailJournalSectionDidTapCreate(_ section: DetailJournalSection, checkinId: String?) {
        // TODO: Open journal editor when implemented
    }
}

// MARK: - Tag Header Shared Layout

private enum TagHeaderLayout {
    static let iconSize: CGFloat = 14
    static let headerFont: UIFont = .projectFont(ofSize: 13, weight: .semibold)
    static let iconToLabelSpacing: CGFloat = 4
    static let headerToContentSpacing: CGFloat = 8

    /// Creates a header row with icon + label, used by both IntensityTagView and DimensionTagView.
    static func makeHeaderStack(iconName: String, title: String) -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .themeTextSecondary
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { make in make.width.height.equalTo(iconSize) }

        let label = UILabel()
        label.font = headerFont
        label.textColor = .themeTextSecondary
        label.text = title

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = iconToLabelSpacing
        stack.alignment = .center
        return stack
    }
}

// MARK: - Tag Card Container

/// Shared dark-card chrome for IntensityTagView and DimensionTagView. Wraps any inner content
/// stack in a `applyDarkGlassCardEffect` card with the standard tag-card padding.
private class TagCardContainer: UIView {
    let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = CheckInDetailLayout.tagCardCornerRadius
        view.clipsToBounds = true
        return view
    }()
    private let visualEffectView = UIVisualEffectView()
    let bodyContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(cardView)
        ViewComponentConstants.applyDarkGlassCardEffect(
            to: cardView,
            visualEffectView: visualEffectView,
            contentView: bodyContainer,
            cornerRadius: CheckInDetailLayout.tagCardCornerRadius
        )
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bodyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(CheckInDetailLayout.tagCardContentPadding)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - IntensityTagView

/// Dark card with header + a row of dots: filled up to the selected level, outlined for the rest.
private class IntensityTagView: TagCardContainer {

    private enum Layout {
        static let dotSize: CGFloat = 16
        static let dotSpacing: CGFloat = 6
    }

    private let dotsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Layout.dotSpacing
        stack.alignment = .center
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        let headerStack = TagHeaderLayout.makeHeaderStack(
            iconName: "rays",
            title: NSLocalizedString("checkin_detail_intensity", comment: "")
        )

        let mainStack = UIStackView(arrangedSubviews: [headerStack, dotsStack])
        mainStack.axis = .vertical
        mainStack.spacing = TagHeaderLayout.headerToContentSpacing
        mainStack.alignment = .leading
        bodyContainer.addSubview(mainStack)

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(level: Int, totalLevels: Int, color: UIColor) {
        // Rebuild dots
        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for i in 0..<totalLevels {
            let dot = UIView()
            dot.layer.cornerRadius = Layout.dotSize / 2
            dot.snp.makeConstraints { make in make.width.height.equalTo(Layout.dotSize) }

            if i < level {
                dot.backgroundColor = color
            } else {
                dot.backgroundColor = .clear
                dot.layer.borderWidth = 1.5
                dot.layer.borderColor = UIColor.white.cgColor
            }

            dotsStack.addArrangedSubview(dot)
        }
    }
}

// MARK: - DimensionTagView

/// Dark card with header + colored topic label below.
private class DimensionTagView: TagCardContainer {

    private let topicLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 17, weight: .regular)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        let headerStack = TagHeaderLayout.makeHeaderStack(
            iconName: "list.bullet",
            title: NSLocalizedString("checkin_detail_dimension", comment: "")
        )

        let mainStack = UIStackView(arrangedSubviews: [headerStack, topicLabel])
        mainStack.axis = .vertical
        mainStack.spacing = TagHeaderLayout.headerToContentSpacing
        mainStack.alignment = .leading
        bodyContainer.addSubview(mainStack)

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(topicLabel: String, topicColor: UIColor) {
        self.topicLabel.text = topicLabel
        self.topicLabel.textColor = topicColor
    }
}
