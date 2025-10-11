//
//  InnerCosmoViewPresenter.swift
//

import Firebase

class InnerCosmoViewPresenter: InnerCosmoViewPresenterType {
    
    weak var delegate: InnerCosmoViewPresenterDelegate?
    private var loadedModel: HomeViewModel = HomeViewModel(isLoading: false) {
        didSet {
            delegate?.didUpdate(viewModel: loadedModel)
        }
    }
    private var isFetchingData: Bool = false
    
    private var isWaitingRemoteConfig = false
    private var dataAccessQueue = DispatchQueue.init(label: "home_data",attributes: .concurrent)
    
    private var user: UserProtocol
    
    init(user: User = User.shared) {
        self.user = user
        
        NotificationCenter.default.addObserver(self, selector: #selector(userIdentityChange), name: NSNotification.Name(rawValue: Notification.UserIdentityChange), object: nil)
    }
    
    public func fetchData(isUpdate: Bool = false) {
        
        if isFetchingData {
            return
        }
        
        // Fetch data, then update the view
        if !isUpdate {
            loadedModel.isLoading = true
        }
        isFetchingData = true
    }
    
    @objc private func userIdentityChange() {}
    
    //MARK: - tableview delegate/ data source related
    
    public func numberOfSectionsOnTableView() -> Int {
        
        return 0
    }
}
