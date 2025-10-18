//
//  QuestProgressLineView.swift
//

import UIKit
import SnapKit

class QuestProgressLineView: UIView {
    
    // MARK: - Progress Drawing Configuration
    private struct Config {
        // Dot sizes for progress visualization
        static let completedDotSize: CGFloat = 12
        static let currentDotSize: CGFloat = 20
        static let futureDotSize: CGFloat = 8
        static let dotHoleRatio: CGFloat = 0.3
        static let lineHeight: CGFloat = 2
    }
    
    // MARK: - Properties
    private var stages: [String] = []
    private var currentStage: Int = 0
    private var titleText: String = ""
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.QuestProgress.titleFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()
    
    private lazy var progressContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var labelsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // MARK: - Initialization
    init() {
        super.init(frame: .zero)
        setupView()
        showPlaceholderState()
    }
    
    init(stages: [String], currentStage: Int, title: String) {
        super.init(frame: .zero)
        self.stages = stages
        self.currentStage = currentStage
        self.titleText = title
        setupView()
        setupProgress()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        addSubview(titleLabel)
        addSubview(progressContainer)
        addSubview(labelsContainer)
        
        titleLabel.text = titleText
        
        // Layout
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.QuestProgress.titleTopOffset)
            make.left.right.equalToSuperview().inset(Layout.QuestProgress.containerPadding)
            make.height.equalTo(Layout.QuestProgress.titleHeight)
        }
        
        progressContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.QuestProgress.sectionSpacing)
            make.left.equalToSuperview().inset(Layout.QuestProgress.containerPadding)
            make.height.equalTo(Layout.QuestProgress.progressContainerHeight)
            make.width.equalTo(240)
        }
        
        labelsContainer.snp.makeConstraints { make in
            make.top.equalTo(progressContainer.snp.bottom).offset(Layout.QuestProgress.sectionSpacing)
            make.left.right.equalTo(progressContainer)
            make.height.equalTo(Layout.QuestProgress.labelsContainerHeight)
            make.bottom.equalToSuperview().inset(Layout.QuestProgress.bottomPadding)
        }
    }
    
    private func setupProgress() {
        // Clear existing views
        progressContainer.subviews.forEach { $0.removeFromSuperview() }
        labelsContainer.subviews.forEach { $0.removeFromSuperview() }
        
        guard !stages.isEmpty else { return }
        
        let totalStages = stages.count
        
        // Store dots for line positioning
        var dots: [UIView] = []
        
        // Create a stack view for proper dot distribution
        let dotStackView = UIStackView()
        dotStackView.axis = .horizontal
        dotStackView.distribution = .equalSpacing
        dotStackView.alignment = .center
        progressContainer.addSubview(dotStackView)
        
        dotStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Create a stack view for labels
        let labelStackView = UIStackView()
        labelStackView.axis = .horizontal
        labelStackView.distribution = .equalSpacing
        labelStackView.alignment = .center
        labelsContainer.addSubview(labelStackView)
        
        labelStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Create dots and labels
        for (index, stageText) in stages.enumerated() {
            let stageNumber = index + 1
            let isCompleted = stageNumber < currentStage
            let isCurrent = stageNumber == currentStage
            
            // Create dot
            let dot = createDot(isCompleted: isCompleted, isCurrent: isCurrent)
            dotStackView.addArrangedSubview(dot)
            dots.append(dot)
            
            // Create label
            let label = createLabel(text: stageText)
            labelStackView.addArrangedSubview(label)
        }
        
        // Create lines connecting first to last dot (only if more than 1 stage)
        if totalStages > 1 {
            let firstDot = dots[0]
            let lastDot = dots[totalStages - 1]
            
            // Background line from first to last dot
            let backgroundLine = UIView()
            backgroundLine.backgroundColor = .systemGray4
            backgroundLine.layer.cornerRadius = Config.lineHeight / 2
            progressContainer.addSubview(backgroundLine)
            
            backgroundLine.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(firstDot.snp.centerX)
                make.right.equalTo(lastDot.snp.centerX)
                make.height.equalTo(Config.lineHeight)
            }
            
            // Progress line (if there's progress)
            if currentStage > 1 {
                let progressLine = UIView()
                progressLine.backgroundColor = .systemBlue
                progressLine.layer.cornerRadius = Config.lineHeight / 2
                progressContainer.addSubview(progressLine)
                
                let currentDot = dots[currentStage - 1] // currentStage is 1-based
                
                progressLine.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.left.equalTo(firstDot.snp.centerX)
                    make.right.equalTo(currentDot.snp.centerX)
                    make.height.equalTo(Config.lineHeight)
                }
            }
        }
    }
    
    private func createDot(isCompleted: Bool, isCurrent: Bool) -> UIView {
        let container = UIView()
        
        // Choose color and size
        let color: UIColor
        let size: CGFloat
        
        if isCompleted {
            color = .systemGreen
            size = Config.completedDotSize
        } else if isCurrent {
            color = .systemOrange
            size = Config.currentDotSize
        } else {
            color = .systemGray4
            size = Config.futureDotSize
        }
        
        // Main dot
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = size / 2
        container.addSubview(dot)
        
        // Layout
        container.snp.makeConstraints { make in
            make.size.equalTo(size)
        }
        
        dot.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return container
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.projectFont(ofSize: Layout.QuestProgress.labelFontSize, weight: .medium)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        return label
    }
    
    // MARK: - Placeholder State
    private func showPlaceholderState() {
        titleLabel.text = "Quest Progress"
        
        // Clear containers
        progressContainer.subviews.forEach { $0.removeFromSuperview() }
        labelsContainer.subviews.forEach { $0.removeFromSuperview() }
        
        // Add just a plain line without dots
        let placeholderLine = UIView()
        placeholderLine.backgroundColor = .systemGray4
        placeholderLine.layer.cornerRadius = Config.lineHeight / 2
        progressContainer.addSubview(placeholderLine)
        
        placeholderLine.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(Config.lineHeight)
        }
    }
    
    // MARK: - Public Methods
    func configure(with lineData: QuestLineData) {
        // Convert QuestLineData to our format
        let sortedPoints = lineData.points.sorted { $0.stage < $1.stage }
        
        // Life stages labels
        let lifeStages = ["Baby", "Child", "Teenager", "Adult", "Elder"]
        let stageTexts = (0...lineData.maxStage).map { index in
            index < lifeStages.count ? lifeStages[index] : "Stage \(index + 1)"
        }
        
        var currentStageNumber = 1
        for point in sortedPoints {
            if point.value > 0 {
                currentStageNumber = point.stage + 1
            }
        }
        
        // Update with real data
        self.stages = stageTexts
        self.currentStage = currentStageNumber
        self.titleText = lineData.title
        
        titleLabel.text = titleText
        setupProgress()
    }
}
