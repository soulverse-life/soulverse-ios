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
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private let intensityTagView = IntensityTagView()
    private let dimensionTagView = DimensionTagView()

    private let drawingSection = DetailDrawingSection()
    private let journalSection = DetailJournalSection()

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
            name: NSNotification.Name(Notification.DrawingSaved), object: nil
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

        contentView.addSubview(drawingSection)
        contentView.addSubview(journalSection)

        view.addSubview(leftArrowButton)
        view.addSubview(rightArrowButton)

        drawingSection.delegate = self
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
            make.centerX.equalToSuperview()
        }

        drawingSection.snp.makeConstraints { make in
            make.top.equalTo(tagsStack.snp.bottom).offset(CheckInDetailLayout.sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalPadding)
        }

        journalSection.snp.makeConstraints { make in
            make.top.equalTo(drawingSection.snp.bottom).offset(CheckInDetailLayout.sectionSpacing)
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

        drawingSection.configure(
            imageURL: viewModel.drawingImageURL,
            prompt: viewModel.reflectionPrompt,
            reflection: viewModel.reflectionText,
            checkinId: viewModel.checkinId
        )

        journalSection.configure(
            title: viewModel.journalTitle,
            content: viewModel.journalContent,
            checkinId: viewModel.checkinId
        )

        scrollView.setContentOffset(.zero, animated: false)
    }
}

// MARK: - Section Delegates

extension CheckInDetailViewController: DetailDrawingSectionDelegate {
    func detailDrawingSectionDidTapCreate(_ section: DetailDrawingSection, checkinId: String?) {
        AppCoordinator.openDrawingCanvas(from: self, checkinId: checkinId)
    }
}

extension CheckInDetailViewController: DetailJournalSectionDelegate {
    func detailJournalSectionDidTapCreate(_ section: DetailJournalSection, checkinId: String?) {
        // TODO: Open journal editor when implemented
    }
}

// MARK: - IntensityTagView

/// Shows "◇ Intensity" label header with a row of small dots indicating the selected level.
private class IntensityTagView: UIView {

    private enum Layout {
        static let dotSize: CGFloat = 10
        static let dotSpacing: CGFloat = 6
        static let headerToDotsSpacing: CGFloat = 8
    }

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 12, weight: .medium)
        label.textColor = .themeTextSecondary
        return label
    }()

    private let dotsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Layout.dotSpacing
        stack.alignment = .center
        return stack
    }()

    private var dotViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let icon = UIImageView(image: UIImage(systemName: "diamond"))
        icon.tintColor = .themeTextSecondary
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { make in make.width.height.equalTo(12) }

        let headerStack = UIStackView(arrangedSubviews: [icon, headerLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 4
        headerStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [headerStack, dotsStack])
        mainStack.axis = .vertical
        mainStack.spacing = Layout.headerToDotsSpacing
        mainStack.alignment = .center
        addSubview(mainStack)

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerLabel.text = NSLocalizedString("checkin_detail_intensity", comment: "")
    }

    func configure(level: Int, totalLevels: Int, color: UIColor) {
        // Rebuild dots
        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        for i in 0..<totalLevels {
            let dot = UIView()
            dot.layer.cornerRadius = Layout.dotSize / 2
            dot.snp.makeConstraints { make in make.width.height.equalTo(Layout.dotSize) }

            if i == level {
                dot.backgroundColor = color
                dot.layer.borderWidth = 2
                dot.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
            } else {
                dot.backgroundColor = color.withAlphaComponent(0.3)
            }

            dotsStack.addArrangedSubview(dot)
            dotViews.append(dot)
        }
    }
}

// MARK: - DimensionTagView

/// Shows "◇ Dimension" label header with a colored topic pill below.
private class DimensionTagView: UIView {

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 12, weight: .medium)
        label.textColor = .themeTextSecondary
        return label
    }()

    private let topicPill: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        label.clipsToBounds = true
        label.layer.cornerRadius = 12
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let icon = UIImageView(image: UIImage(systemName: "diamond"))
        icon.tintColor = .themeTextSecondary
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { make in make.width.height.equalTo(12) }

        let headerStack = UIStackView(arrangedSubviews: [icon, headerLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 4
        headerStack.alignment = .center

        let pillContainer = UIView()
        pillContainer.addSubview(topicPill)
        topicPill.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.height.equalTo(24)
        }

        let mainStack = UIStackView(arrangedSubviews: [headerStack, pillContainer])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.alignment = .center
        addSubview(mainStack)

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerLabel.text = NSLocalizedString("checkin_detail_dimension", comment: "")
    }

    func configure(topicLabel: String, topicColor: UIColor) {
        topicPill.text = "  \(topicLabel)  "
        topicPill.textColor = .white
        topicPill.backgroundColor = topicColor
    }
}
