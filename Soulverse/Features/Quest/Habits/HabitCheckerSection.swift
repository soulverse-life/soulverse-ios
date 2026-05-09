//
//  HabitCheckerSection.swift
//  Soulverse
//
//  Container view that hosts three default habit cards, an optional active
//  custom habit card, and the lock-aware Add Custom Habit button.
//

import UIKit
import SnapKit
import Combine

final class HabitCheckerSection: UIView {
    private enum Layout {
        static let cardSpacing: CGFloat = 12
        static let outerInset: CGFloat = 16
        static let headerSpacing: CGFloat = 8
    }

    private let titleLabel = UILabel()
    private let stack = UIStackView()
    private let exerciseCard = DefaultHabitCard()
    private let waterCard = DefaultHabitCard()
    private let meditationCard = DefaultHabitCard()
    private let customCard = CustomHabitCard()
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
        titleLabel.text = NSLocalizedString("quest_habit_section_title", comment: "")
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .themeTextPrimary

        stack.axis = .vertical
        stack.spacing = Layout.cardSpacing

        stack.addArrangedSubview(exerciseCard)
        stack.addArrangedSubview(waterCard)
        stack.addArrangedSubview(meditationCard)
        stack.addArrangedSubview(customCard)
        stack.addArrangedSubview(addButton)
        customCard.isHidden = true

        let outer = UIStackView(arrangedSubviews: [titleLabel, stack])
        outer.axis = .vertical
        outer.spacing = Layout.headerSpacing
        addSubview(outer)
        outer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }

        exerciseCard.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.exercise.rawValue, amount: amount, telemetry: self?.telemetry)
        }
        waterCard.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.water.rawValue, amount: amount, telemetry: self?.telemetry)
        }
        meditationCard.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.meditation.rawValue, amount: amount, telemetry: self?.telemetry)
        }

        addButton.onTap = { [weak self] in self?.onAddTap?() }
        customCard.onDeleteTap = { [weak self] in
            guard let self = self, let active = self.service.activeCustomHabit() else { return }
            self.onDeleteTap?(active)
        }
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

        exerciseCard.configure(vm.cardModel(
            for: DefaultHabitId.exercise.rawValue,
            titleKey: DefaultHabitId.exercise.titleKey,
            unit: DefaultHabitId.exercise.unit,
            increments: DefaultHabitId.exercise.increments
        ))
        waterCard.configure(vm.cardModel(
            for: DefaultHabitId.water.rawValue,
            titleKey: DefaultHabitId.water.titleKey,
            unit: DefaultHabitId.water.unit,
            increments: DefaultHabitId.water.increments
        ))
        meditationCard.configure(vm.cardModel(
            for: DefaultHabitId.meditation.rawValue,
            titleKey: DefaultHabitId.meditation.titleKey,
            unit: DefaultHabitId.meditation.unit,
            increments: DefaultHabitId.meditation.increments
        ))

        if let active = vm.activeCustomHabit {
            customCard.isHidden = false
            let yKey = HabitDateKey.yesterdayKey(of: todayKey)
            customCard.configure(
                active,
                todayTotal: state.daily[todayKey]?[active.id] ?? 0,
                yesterdayTotal: state.daily[yKey]?[active.id] ?? 0
            )
            customCard.onIncrementTap = { [weak self] amount in
                self?.service.logIncrement(habitId: active.id, amount: amount, telemetry: self?.telemetry)
            }
        } else {
            customCard.isHidden = true
        }

        addButton.configure(vm.addButtonState)
    }
}
