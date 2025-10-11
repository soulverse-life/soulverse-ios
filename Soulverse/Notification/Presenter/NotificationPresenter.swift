//
//  NotificationPresenter.swift
//  KonoSummit
//
//  Created by mingshing on 2022/2/14.
//

import Foundation
import UIKit

class NotificationPresenter: NotificationPresenterType {
    
    var viewModel = NotificationViewModel()
    var delegate: NotificationPresenterDelegate?
    var user: UserProtocol
    var hasAskPermission: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.didUpdateViewModel(viewModel: self.viewModel)
            }
        }
    }
    var notificationCenter: UNUserNotificationCenter
    
    init(
        user: User = User.shared,
        notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
        delegate: NotificationPresenterDelegate? = nil
    ) {
        self.user = user
        self.delegate = delegate
        self.notificationCenter = notificationCenter
        NotificationCenter.default.addObserver(self, selector: #selector(userIdentityChanged), name: NSNotification.Name(rawValue: Notification.UserIdentityChange), object: nil)
        
        self.notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.hasAskPermission = false
            } else {
                self.hasAskPermission = true
            }
        }
    }
    
    
    func fetchData(completion: (()->Void)?) {

        viewModel.status = .fetching
        let currentUserId = user.userId ?? "anonymous"
        NotificationService.getNotificationItems(for: currentUserId) { [weak self] (userId, res) in
            
            guard let weakSelf = self else { return }
            guard userId == ( weakSelf.user.userId ?? "anonymous" ) else { return }
            switch res {
            case .success(let response):
                weakSelf.viewModel.cellViewModels.removeAll()
                let notificationCount = weakSelf.viewModel.addNotificationItems(response)
                if notificationCount < HostAppContants.pagingCount {
                    weakSelf.viewModel.status = .allFetched
                } else {
                    weakSelf.viewModel.status = .partialFetched
                }
            case .failure(let error):
                print(error)
                switch error {
                case .UnAuthorize:
                    weakSelf.viewModel.status = .unauthorized
                default:
                    weakSelf.viewModel.status = .unknownError
                }
                break
            }
            completion?()
            weakSelf.delegate?.didUpdateViewModel(viewModel: weakSelf.viewModel)
        }
        
    }

    func loadNext(completion: (()->Void)?) {
        guard let latestNotification = viewModel.cellViewModels.last else { return }
        
        if viewModel.status != .partialFetched {
            completion?()
            return
        }
        
        viewModel.status = .fetching
        let currentUserId = user.userId ?? "anonymous"
        NotificationService.getNotificationItems(for: currentUserId, from: latestNotification.createdTime) { [weak self] (userId, res) in
            
            guard let weakSelf = self else { return }
            guard userId == ( weakSelf.user.userId ?? "anonymous" ) else { return }
            switch res {
            case .success(let response):
                let newNotificationCount = weakSelf.viewModel.addNotificationItems(response)
                if newNotificationCount < HostAppContants.pagingCount {
                    weakSelf.viewModel.status = .allFetched
                } else {
                    weakSelf.viewModel.status = .partialFetched
                }
                
            case .failure(let error):
                switch error {
                case .UnAuthorize:
                    weakSelf.viewModel.status = .unauthorized
                default:
                    weakSelf.viewModel.status = .unknownError
                }
                break
            }
            completion?()
            weakSelf.delegate?.didUpdateViewModel(viewModel: weakSelf.viewModel)
        }
        
    }
    
    func updateNotificationReadStatus () {
        if viewModel.hasUnreadNotification {
            NotificationService.updateNotificationReadTime() {_ in
            }
        }
        viewModel.clearUnreadStatus()
        delegate?.didUpdateViewModel(viewModel: viewModel)
    }
    
    @objc private func userIdentityChanged() {
        
        viewModel.clearFetchedData()
        fetchData(completion: nil)
    }
    
    func numberOfItems() -> Int {
        
        return viewModel.cellViewModels.count
    }
    
    func viewModelForIndex(_ row: Int) -> NotificationItemCellViewModel? {
        
        guard viewModel.cellViewModels.count > row else { return nil }
        return viewModel.cellViewModels[row]
    }
    
    func askNotificationPermission() {
        
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            guard let weakSelf = self else { return }
            weakSelf.hasAskPermission = true
            weakSelf.user.hasShownRequestPermissionAlert()
        }
    }
    
}
