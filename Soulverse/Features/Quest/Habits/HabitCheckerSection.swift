//
//  HabitCheckerSection.swift
//  Soulverse
//
//  Single glass card containing the section title and one row per active
//  habit (three defaults + optional custom + the Add Custom Habit button).
//  Per the design feedback, habits are sub-sections of ONE card, separated
//  by themeSeparator dividers — they no longer have their own card chrome.
//

import UIKit
import SnapKit
import Combine

final class HabitCheckerSection: UIView {
    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let outerInset: CGFloat = 16
        static let titleToRowsSpacing: CGFloat = 12
        static let rowSpacing: CGFloat = 0   // dividers carry separation
        static let dividerHeight: CGFloat = 1
        static let containerPadding: CGFloat = 16
        static let titleFontSize: CGFloat = 20
    }

    private let visualEffectView = UIVisualEffectView(effect: nil)
    private let cardContent = UIView()

    private let titleLabel = UILabel()
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
        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .regular)
        titleLabel.textColor = .themeTextPrimary

        rowsStack.axis = .vertical
        rowsStack.spacing = Layout.rowSpacing

        // Order: exercise, water, meditation, custom (optional), add button
        addRow(exerciseRow)
        addRow(waterRow)
        addRow(meditationRow)
        addRow(customRow)
        addRow(addButton)
        customRow.isHidden = true

        let outer = UIStackView(arrangedSubviews: [titleLabel, rowsStack])
        outer.axis = .vertical
        outer.spacing = Layout.titleToRowsSpacing

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

        exerciseRow.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.exercise.rawValue, amount: amount, telemetry: self?.telemetry)
        }
        waterRow.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.water.rawValue, amount: amount, telemetry: self?.telemetry)
        }
        meditationRow.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.meditation.rawValue, amount: amount, telemetry: self?.telemetry)
        }

        addButton.onTap = { [weak self] in self?.onAddTap?() }
        customRow.onDeleteTap = { [weak self] in
            guard let self = self, let active = self.service.activeCustomHabit() else { return }
            self.onDeleteTap?(active)
        }
    }

    /// Append a row + a divider underneath. Last divider is hidden in `rerender()`.
    private func addRow(_ view: UIView) {
        rowsStack.addArrangedSubview(view)
        let divider = UIView()
        divider.backgroundColor = .themeSeparator
        divider.snp.makeConstraints { make in
            make.height.equalTo(Layout.dividerHeight)
        }
        rowsStack.addArrangedSubview(divider)
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

        exerciseRow.configure(vm.cardModel(
            for: DefaultHabitId.exercise.rawValue,
            titleKey: DefaultHabitId.exercise.titleKey,
            unit: DefaultHabitId.exercise.unit,
            increments: DefaultHabitId.exercise.increments
        ))
        waterRow.configure(vm.cardModel(
            for: DefaultHabitId.water.rawValue,
            titleKey: DefaultHabitId.water.titleKey,
            unit: DefaultHabitId.water.unit,
            increments: DefaultHabitId.water.increments
        ))
        meditationRow.configure(vm.cardModel(
            for: DefaultHabitId.meditation.rawValue,
            titleKey: DefaultHabitId.meditation.titleKey,
            unit: DefaultHabitId.meditation.unit,
            increments: DefaultHabitId.meditation.increments
        ))

        if let active = vm.activeCustomHabit {
            customRow.isHidden = false
            let yKey = HabitDateKey.yesterdayKey(of: todayKey)
            customRow.configure(
                active,
                todayTotal: state.daily[todayKey]?[active.id] ?? 0,
                yesterdayTotal: state.daily[yKey]?[active.id] ?? 0
            )
            customRow.onIncrementTap = { [weak self] amount in
                self?.service.logIncrement(habitId: active.id, amount: amount, telemetry: self?.telemetry)
            }
        } else {
            customRow.isHidden = true
        }

        addButton.configure(vm.addButtonState)
        updateDividerVisibility()
    }

    /// Hide dividers under rows whose row is hidden, and the divider after
    /// the last visible row.
    private func updateDividerVisibility() {
        let views = rowsStack.arrangedSubviews
        // Rows are at even indices; dividers at odd.
        for i in stride(from: 0, to: views.count, by: 2) {
            let row = views[i]
            let divider = (i + 1 < views.count) ? views[i + 1] : nil
            divider?.isHidden = row.isHidden
        }
        // Hide the divider after the last visible row.
        var lastVisibleRowIdx: Int?
        for i in stride(from: 0, to: views.count, by: 2) where !views[i].isHidden {
            lastVisibleRowIdx = i
        }
        if let last = lastVisibleRowIdx, last + 1 < views.count {
            views[last + 1].isHidden = true
        }
    }
}
