//
//  HabitCheckerSection.swift
//  Soulverse
//
//  Single glass card containing the section header (title + subtitle) and
//  one accent-tinted sub-card per habit (three defaults + optional custom +
//  the Add Custom Habit button). Each sub-card is fully self-contained
//  visually; the outer card provides the glass-effect chrome.
//

import UIKit
import SnapKit
import Combine

final class HabitCheckerSection: UIView {
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let containerPadding: CGFloat = 26
        static let headerSpacing: CGFloat = 4
        static let headerToRowsSpacing: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let titleFontSize: CGFloat = 20
        static let subtitleFontSize: CGFloat = 14
    }

    private let visualEffectView = UIVisualEffectView(effect: nil)
    private let cardContent = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let rowsStack = UIStackView()

    private let exerciseRow = DefaultHabitCard()
    private let waterRow = DefaultHabitCard()
    private let meditationRow = DefaultHabitCard()
    private let customRow = CustomHabitCard()
    private let addButton = AddCustomHabitButton()

    private let service: FirestoreHabitService
    private let telemetry: HabitTelemetry?
    private var cancellables: Set<AnyCancellable> = []
    private var distinctCheckInDays: Int = 0

    var onAddTap: (() -> Void)?
    var onDeleteTap: ((CustomHabit) -> Void)?

    init(service: FirestoreHabitService, telemetry: HabitTelemetry? = HabitTelemetry()) {
        self.service = service
        self.telemetry = telemetry
        super.init(frame: .zero)
        setupView()
        wireService()
    }
    required init?(coder: NSCoder) { fatalError() }

    /// Update the day-counter that drives the Add Custom Habit lock state.
    func update(distinctCheckInDays days: Int) {
        self.distinctCheckInDays = days
        rerender()
    }

    private func setupView() {
        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true

        titleLabel.text = NSLocalizedString("quest_habit_section_title", comment: "")
        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        titleLabel.textColor = .themeTextPrimary

        subtitleLabel.text = NSLocalizedString("quest_habit_section_subtitle", comment: "")
        subtitleLabel.font = .projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        subtitleLabel.textColor = .themeTextSecondary

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = Layout.headerSpacing

        rowsStack.axis = .vertical
        rowsStack.spacing = Layout.rowSpacing

        // Order: exercise, water, meditation, custom (optional), add button.
        rowsStack.addArrangedSubview(exerciseRow)
        rowsStack.addArrangedSubview(waterRow)
        rowsStack.addArrangedSubview(meditationRow)
        rowsStack.addArrangedSubview(customRow)
        rowsStack.addArrangedSubview(addButton)
        customRow.isHidden = true

        let outer = UIStackView(arrangedSubviews: [headerStack, rowsStack])
        outer.axis = .vertical
        outer.spacing = Layout.headerToRowsSpacing

        cardContent.addSubview(outer)
        outer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.containerPadding)
        }

        ViewComponentConstants.applyGlassCardEffect(
            to: self,
            visualEffectView: visualEffectView,
            contentView: cardContent,
            cornerRadius: Layout.cornerRadius
        )
        cardContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        exerciseRow.delegate = self
        waterRow.delegate = self
        meditationRow.delegate = self
        customRow.delegate = self

        addButton.onTap = { [weak self] in self?.onAddTap?() }
    }

    private func wireService() {
        service.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rerender() }
            .store(in: &cancellables)
    }

    private func rerender() {
        let todayKey = HabitDateKey.dateKey(for: Date(), in: .current)
        let state = service.currentState
        let vm = HabitCheckerViewModel(state: state, todayKey: todayKey, distinctCheckInDays: distinctCheckInDays)

        configureDefault(exerciseRow, defaultId: .exercise, vm: vm)
        configureDefault(waterRow, defaultId: .water, vm: vm)
        configureDefault(meditationRow, defaultId: .meditation, vm: vm)

        if let active = vm.activeCustomHabit {
            customRow.isHidden = false
            let yKey = HabitDateKey.yesterdayKey(of: todayKey)
            customRow.configure(
                active,
                todayTotal: state.daily[todayKey]?[active.id] ?? 0,
                yesterdayTotal: state.daily[yKey]?[active.id] ?? 0
            )
        } else {
            customRow.isHidden = true
        }

        addButton.configure(vm.addButtonState)
    }

    private func configureDefault(_ card: DefaultHabitCard, defaultId: DefaultHabitId, vm: HabitCheckerViewModel) {
        let model = vm.cardModel(
            for: defaultId.rawValue,
            titleKey: defaultId.titleKey,
            unit: defaultId.unit,
            increments: defaultId.increments
        )
        card.configure(model, accentColor: defaultId.accentColor, iconName: defaultId.iconName)
    }

    /// Map a DefaultHabitCard back to its DefaultHabitId via identity. The
    /// three default rows are persistent `lazy var`s so `===` is reliable.
    private func defaultId(for card: DefaultHabitCard) -> DefaultHabitId? {
        if card === exerciseRow   { return .exercise }
        if card === waterRow      { return .water }
        if card === meditationRow { return .meditation }
        return nil
    }
}

// MARK: - DefaultHabitCardDelegate

extension HabitCheckerSection: DefaultHabitCardDelegate {
    func defaultHabitCard(_ card: DefaultHabitCard, didTapIncrement amount: Int) -> Bool {
        guard let id = defaultId(for: card) else { return false }
        return service.logIncrement(habitId: id.rawValue, amount: amount, telemetry: telemetry)
    }
}

// MARK: - CustomHabitCardDelegate

extension HabitCheckerSection: CustomHabitCardDelegate {
    func customHabitCard(_ card: CustomHabitCard, didTapIncrement amount: Int) -> Bool {
        guard let active = service.activeCustomHabit() else { return false }
        return service.logIncrement(habitId: active.id, amount: amount, telemetry: telemetry)
    }

    func customHabitCardDidTapDelete(_ card: CustomHabitCard) {
        guard let active = service.activeCustomHabit() else { return }
        onDeleteTap?(active)
    }
}
