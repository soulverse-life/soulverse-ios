//
//  FirestoreHabitService.swift
//  Soulverse
//
//  Single-doc Firestore service for users/{uid}/habits/state (Shape α).
//  Atomic increments via FieldValue.increment on nested field paths.
//

import Foundation
import Combine
import FirebaseFirestore

/// In-memory representation of `users/{uid}/habits/state` (Shape α).
struct HabitState: Equatable {
    var daily: [String: [String: Int]]      // ["2026-05-01": ["exercise": 30, ...]]
    var customHabits: [String: CustomHabit]  // keyed by habit id

    static let empty = HabitState(daily: [:], customHabits: [:])
}

/// Abstracts Firestore for testability.
protocol HabitStore: AnyObject {
    func observe(_ onUpdate: @escaping (HabitState) -> Void) -> () -> Void
    func incrementDaily(date: String, habitId: String, amount: Int)
    func upsertCustomHabit(_ habit: CustomHabit)
    func softDeleteCustomHabit(id: String, deletedAt: Date)
}

final class FirestoreHabitService {

    private let uid: String
    private let store: HabitStore
    private let stateSubject = CurrentValueSubject<HabitState, Never>(.empty)
    private var unobserve: (() -> Void)?

    var statePublisher: AnyPublisher<HabitState, Never> { stateSubject.eraseToAnyPublisher() }
    var currentState: HabitState { stateSubject.value }

    init(uid: String, store: HabitStore? = nil) {
        self.uid = uid
        self.store = store ?? FirestoreHabitStore(uid: uid)
        self.unobserve = self.store.observe { [weak self] state in
            self?.stateSubject.send(state)
        }
    }

    deinit { unobserve?() }

    // MARK: - Reads

    func todaysTotal(habitId: String, in timeZone: TimeZone = .current) -> Int {
        let key = HabitDateKey.dateKey(for: Date(), in: timeZone)
        return stateSubject.value.daily[key]?[habitId] ?? 0
    }

    func yesterdaysTotal(habitId: String, in timeZone: TimeZone = .current) -> Int {
        let today = HabitDateKey.dateKey(for: Date(), in: timeZone)
        let yesterday = HabitDateKey.yesterdayKey(of: today)
        return stateSubject.value.daily[yesterday]?[habitId] ?? 0
    }

    /// Returns the single active custom habit (or nil). MVP cap = 1 active slot.
    func activeCustomHabit() -> CustomHabit? {
        stateSubject.value.customHabits.values.first(where: { $0.isActive })
    }

    // MARK: - Writes

    /// Atomically increment a habit's daily total. Records into the map at the
    /// device's current local date.
    func logIncrement(
        habitId: String,
        amount: Int,
        at date: Date = Date(),
        in timeZone: TimeZone = .current,
        telemetry: HabitTelemetry? = nil
    ) {
        let dateKey = HabitDateKey.dateKey(for: date, in: timeZone)
        store.incrementDaily(date: dateKey, habitId: habitId, amount: amount)
        telemetry?.observe(writeAt: date, in: timeZone)
    }

    @discardableResult
    func createCustomHabit(name: String, unit: String, increments: [Int]) -> CustomHabit {
        let habit = CustomHabit(
            id: HabitData.generateCustomHabitId(),
            name: name, unit: unit, increments: increments,
            createdAt: Date(), deletedAt: nil
        )
        store.upsertCustomHabit(habit)
        return habit
    }

    func softDeleteCustomHabit(id: String) {
        store.softDeleteCustomHabit(id: id, deletedAt: Date())
    }
}

// MARK: - Production conformance

final class FirestoreHabitStore: HabitStore {
    private let docRef: DocumentReference

    init(uid: String, db: Firestore = Firestore.firestore()) {
        self.docRef = db.collection("users").document(uid).collection("habits").document("state")
    }

    func observe(_ onUpdate: @escaping (HabitState) -> Void) -> () -> Void {
        let listener = docRef.addSnapshotListener { snapshot, _ in
            let data = snapshot?.data() ?? [:]
            let daily = (data["daily"] as? [String: [String: Int]]) ?? [:]
            let rawCustom = (data["customHabits"] as? [String: [String: Any]]) ?? [:]
            var customs: [String: CustomHabit] = [:]
            for (id, raw) in rawCustom {
                guard
                    let name = raw["name"] as? String,
                    let unit = raw["unit"] as? String,
                    let increments = raw["increments"] as? [Int],
                    let createdAt = (raw["createdAt"] as? Timestamp)?.dateValue()
                else { continue }
                let deletedAt = (raw["deletedAt"] as? Timestamp)?.dateValue()
                customs[id] = CustomHabit(
                    id: id, name: name, unit: unit, increments: increments,
                    createdAt: createdAt, deletedAt: deletedAt
                )
            }
            onUpdate(HabitState(daily: daily, customHabits: customs))
        }
        return { listener.remove() }
    }

    func incrementDaily(date: String, habitId: String, amount: Int) {
        // FieldValue.increment on nested field path is atomic.
        let path = "daily.\(date).\(habitId)"
        docRef.setData([path: FieldValue.increment(Int64(amount))], merge: true) { error in
            if let error = error {
                assertionFailure("FirestoreHabitStore.incrementDaily failed: \(error)")
            }
        }
    }

    func upsertCustomHabit(_ habit: CustomHabit) {
        let payload: [String: Any] = [
            "id":         habit.id,
            "name":       habit.name,
            "unit":       habit.unit,
            "increments": habit.increments,
            "createdAt":  Timestamp(date: habit.createdAt),
            "deletedAt":  habit.deletedAt.map(Timestamp.init(date:)) as Any
        ]
        let path = "customHabits.\(habit.id)"
        docRef.setData([path: payload], merge: true)
    }

    func softDeleteCustomHabit(id: String, deletedAt: Date) {
        let path = "customHabits.\(id).deletedAt"
        docRef.updateData([path: Timestamp(date: deletedAt)])
    }
}

// MARK: - In-memory test double

final class InMemoryHabitStore: HabitStore {
    private var state: HabitState = .empty
    private var listener: ((HabitState) -> Void)?

    func observe(_ onUpdate: @escaping (HabitState) -> Void) -> () -> Void {
        listener = onUpdate
        onUpdate(state)
        return { [weak self] in self?.listener = nil }
    }

    func incrementDaily(date: String, habitId: String, amount: Int) {
        var day = state.daily[date] ?? [:]
        day[habitId] = (day[habitId] ?? 0) + amount
        state.daily[date] = day
        listener?(state)
    }

    func upsertCustomHabit(_ habit: CustomHabit) {
        state.customHabits[habit.id] = habit
        listener?(state)
    }

    func softDeleteCustomHabit(id: String, deletedAt: Date) {
        guard let existing = state.customHabits[id] else { return }
        state.customHabits[id] = CustomHabit(
            id: existing.id, name: existing.name, unit: existing.unit,
            increments: existing.increments,
            createdAt: existing.createdAt, deletedAt: deletedAt
        )
        listener?(state)
    }

    /// Test helper: simulate an external write hitting the store.
    func simulateRemoteUpdate(_ newState: HabitState) {
        state = newState
        listener?(state)
    }
}
