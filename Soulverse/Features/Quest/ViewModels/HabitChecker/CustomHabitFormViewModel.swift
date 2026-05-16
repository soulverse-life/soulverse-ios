//
//  CustomHabitFormViewModel.swift
//  Soulverse
//
//  Validation state machine for the Custom Habit creation form.
//

import Foundation

final class CustomHabitFormViewModel {
    enum FormError: Equatable {
        case nameRequired
        case nameTooLong
        case unitRequired
        case unitTooLong
        case incrementsRequired
        case duplicateIncrements
        case nonPositiveIncrement
    }

    private(set) var name: String = ""
    private(set) var unit: String = ""
    private(set) var increments: [Int] = []
    private(set) var errors: Set<FormError> = []

    private static let nameMin = 1
    private static let nameMax = 24
    private static let unitMin = 1
    private static let unitMax = 8

    var isValid: Bool {
        errors.isEmpty && !name.isEmpty && !unit.isEmpty && increments.count == 3
    }

    func update(name: String, unit: String, increments: [Int]) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.unit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        self.increments = increments
        validate()
    }

    func suggestedIncrements(forUnit unit: String) -> [Int]? {
        let lower = unit.lowercased()
        if lower.contains("min") || lower.contains("hour") || lower.contains("sec") {
            return [5, 10, 15]
        }
        if lower == "ml" || lower == "oz" || lower == "cup" || lower == "cups" {
            return [100, 200, 300]
        }
        if lower.contains("page") || lower == "book" || lower == "books" {
            return [1, 5, 10]
        }
        return nil
    }

    private func validate() {
        var errs: Set<FormError> = []
        if name.count < Self.nameMin { errs.insert(.nameRequired) }
        if name.count > Self.nameMax { errs.insert(.nameTooLong) }
        if unit.count < Self.unitMin { errs.insert(.unitRequired) }
        if unit.count > Self.unitMax { errs.insert(.unitTooLong) }
        if increments.count != 3 { errs.insert(.incrementsRequired) }
        if Set(increments).count != increments.count { errs.insert(.duplicateIncrements) }
        if increments.contains(where: { $0 <= 0 }) { errs.insert(.nonPositiveIncrement) }
        errors = errs
    }
}
