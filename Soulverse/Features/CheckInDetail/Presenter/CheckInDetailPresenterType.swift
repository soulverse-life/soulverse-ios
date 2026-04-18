//
//  CheckInDetailPresenterType.swift
//  Soulverse
//

import Foundation

protocol CheckInDetailPresenterDelegate: AnyObject {
    func didUpdateViewModel(_ viewModel: CheckInDetailViewModel)
}

protocol CheckInDetailPresenterType {
    var delegate: CheckInDetailPresenterDelegate? { get set }
    func loadCurrentCheckIn()
    func goToNext()
    func goToPrevious()
}
