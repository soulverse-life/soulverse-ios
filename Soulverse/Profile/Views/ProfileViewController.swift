//
//  ProfileViewController.swift
//  KonoSummit
//


import UIKit
import Toaster


class ProfileViewController: ViewController {

    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .backgroundBlack
        table.showsVerticalScrollIndicator = false
        table.separatorStyle = .none
        
        table.register(
            ProfileCell.self,
            forCellReuseIdentifier: String(describing: ProfileCell.self)
        )
        table.delegate = self
        table.dataSource = self
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ViewComponentConstants.miniBarHeight - 20.0, right: 0)

        return table
    }()
    
    
    private lazy var loginHeaderView: UIView = { [weak self] in
        let actionButton: UIButton = {
            let button = UIButton()
            button.setTitle(NSLocalizedString("loginSignup", comment: ""), for: .normal)
            button.setTitleColor(.primaryBlack, for: .normal)
            button.titleLabel?.font = .projectFont(ofSize: 14.0, weight: .bold)
            button.backgroundColor = .themeMainColor
            button.layer.cornerRadius = 8
            return button
        }()
        actionButton.addTarget(self, action: #selector(loginUser), for: .touchUpInside)
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: DeviceConstants.width, height: 88))
        headerView.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(DeviceConstants.width - 40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
        return headerView
    }()
    
    private lazy var verifyHeaderView: UIView = { [weak self] in
        
        let symbol: UIImageView = {
            let imageView = UIImageView()
            let image = UIImage(named: "iconWarningNopadding")
            imageView.image = image
            return imageView
        }()
        
        let actionDescriptionLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 1
            label.font = .projectFont(ofSize: 14, weight: .bold)
            label.textColor = .primaryWhite
            label.textAlignment = .left
            label.text = NSLocalizedString("profile_verify_description", comment: "")
            return label
        }()
        
        let actionTitleLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 1
            label.font = .projectFont(ofSize: 14, weight: .regular)
            label.textColor = .primaryGray
            label.textAlignment = .left
            label.text = NSLocalizedString("profile_verify_action_title", comment: "")
            return label
        }()
        
        let actionButton: UIButton = {
            let button = UIButton()
            button.setTitle(NSLocalizedString("profile_resend", comment: ""), for: .normal)
            button.setTitleColor(.themeMainColor, for: .normal)
            button.titleLabel?.font = .projectFont(ofSize: 14.0, weight: .bold)
            button.backgroundColor = .clear
            button.layer.cornerRadius = 8
            button.layer.borderColor = UIColor.themeMainColor.cgColor
            button.layer.borderWidth = 1
            return button
        }()
        actionButton.addTarget(self, action: #selector(didTapResendBtn), for: .touchUpInside)
        
        let separator = SummitSeparator()
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: DeviceConstants.width, height: 168))
        headerView.addSubview(symbol)
        headerView.addSubview(actionDescriptionLabel)
        headerView.addSubview(actionTitleLabel)
        headerView.addSubview(actionButton)
        headerView.addSubview(separator)
        
        symbol.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
            make.width.equalTo(18)
            make.height.equalTo(16)
        }
        
        actionDescriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(symbol.snp.right).offset(10)
            make.top.equalTo(symbol)
        }
        
        actionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(symbol.snp.bottom).offset(10)
            make.left.equalTo(symbol)
        }
        actionButton.snp.makeConstraints { make in
            make.left.equalTo(symbol)
            make.top.equalTo(actionTitleLabel.snp.bottom).offset(20)
            make.width.equalTo(116)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.equalToSuperview().inset(20).priority(.low)
            make.top.equalTo(actionButton.snp.bottom).offset(20)
        }
        return headerView
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        let singleTap = UITapGestureRecognizer(target:self, action:#selector(openPersonalInfo))
        imageView.addGestureRecognizer(singleTap)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    var presenter: ProfilePresenterType?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        presenter = ProfilePresenter(delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.cleanTitles()
        setupView()
        showLoading = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        if #available(iOS 18.0, *) {
            self.tabBarController?.setTabBarHidden(false, animated: false)
        }
        showLoading = false
        if let status = presenter?.viewModel?.status {
            avatarImageView.isHidden = status != .anonymous ? false : true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        avatarImageView.isHidden = true
        if #available(iOS 18.0, *) {
            if isCurrentTabRootVC {
                self.tabBarController?.setTabBarHidden(true, animated: false)
            }
        }
    }
    
    private func setupView() {
        
        navigationController?.navigationBar.prefersLargeTitles = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(avatarImageView)
        avatarImageView.layer.cornerRadius = ViewComponentConstants.ImageSizeForLargeState / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(ViewComponentConstants.ImageRightMargin)
            make.bottom.equalToSuperview().inset(ViewComponentConstants.ImageBottomMarginForLargeState)
            make.size.equalTo(ViewComponentConstants.ImageSizeForLargeState)
        }
    }
    
    private func updateHeaderView(_ status: ProfileStatus) {
        
        switch status {
        case .anonymous:
            tableView.tableHeaderView = loginHeaderView
            avatarImageView.isHidden = true
        case .unverified:
            tableView.tableHeaderView = verifyHeaderView
            avatarImageView.kf.setImage(with: URL(string: presenter!.user.avatarImageURL))
            if self.isVisible {
                avatarImageView.isHidden = false
            }
        case .basic:
            tableView.tableHeaderView = nil
            avatarImageView.kf.setImage(with: URL(string: presenter!.user.avatarImageURL))
            if self.isVisible {
                avatarImageView.isHidden = false
            }
        }
    }
    
}

extension ProfileViewController: ProfilePresenterDelegate {
    func didSendVerifyEmail(error: Error?) {
        
        if error == nil {
            Toast(text: NSLocalizedString("profile_verify_email_sent", comment: ""), duration: Delay.short).show()
        } else {
            Toast(text: NSLocalizedString("message_error_server", comment: ""), duration: Delay.short).show()
        }
    }
    
    func switchToHome() {

    }
    
    func rowAction(contentType: ProfileContentCategory) {
        switch contentType {
        case .PersonalInfo:
            openPersonalInfo()
        case .Policy:
            openPolicy()
        case .Privacy:
            openPrivacy()
        case .FAQ:
            openFAQ()
        case .Contact:
            contactUs()
        case .Logout:
            logoutUser()
        }
    }
    
    func didUpdateViewModel(viewModel: ProfileViewModel) {
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.updateHeaderView(viewModel.status)
            weakSelf.title = viewModel.status == .anonymous ? NSLocalizedString("Guest", comment: "") : NSLocalizedString("Account", comment: "")
            weakSelf.tabBarController?.cleanTitles()
            weakSelf.tableView.reloadData()
        }
    }
}

extension ProfileViewController {
    
    @objc func openPersonalInfo() {
        let vc = PersonalInfoViewController()
        vc.hidesBottomBarWhenPushed = true
        show(vc, sender: self)
    }
    
    func openPolicy() {
        
        let vc = WebViewController(title: NSLocalizedString("profile_policy", comment: ""), targetUrl: HostAppContants.policyUrl)
        show(vc, sender: self)
        
    }
    
    func openPrivacy() {
        let vc = WebViewController(title: NSLocalizedString("profile_privacy", comment: ""), targetUrl: HostAppContants.privacyUrl)
        show(vc, sender: self)
    }
    
    func openFAQ() {
        let vc = WebViewController(title: NSLocalizedString("profile_faq", comment: ""), targetUrl: HostAppContants.faqUrl)
        show(vc, sender: self)
    }
    
    func contactUs() {
        
        AppCoordinator.openMailService(from: self, withSubject: HostAppContants.contactSubject)
        
    }
    
    @objc func loginUser() {
        
        AppCoordinator.openLoginPage(from: self, page: .Account)
    }
    
    @objc func didTapResendBtn() {
        presenter?.resendVerifyEmail()
    }
    
    func logoutUser() {
        
        let cancelAction = SummitAlertAction(title: NSLocalizedString("profile_logout_alert_action_cancel", comment: ""), style: .default, handler: nil)
        
        let okAction = SummitAlertAction(title: NSLocalizedString("profile_logout_alert_action_ok", comment: ""), style: .destructive) {
            self.presenter?.logout()
        }
        SummitAlertView.shared.show(
            title: NSLocalizedString("profile_logout_alert_title", comment: ""),
            message: NSLocalizedString("profile_logout_alert_description", comment: ""),
            actions: [cancelAction, okAction]
        )
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return presenter?.numberOfSections() ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.numberOfItems(of: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.font = .projectFont(ofSize: 14, weight: .regular)
        titleLabel.textAlignment = .left
        titleLabel.textColor = UIColor.primaryGray
        titleLabel.text = presenter?.titleForSection(section)
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(10)
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cellViewModel = presenter?.viewModelForIndex(section: indexPath.section, row: indexPath.row) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: ProfileCell.self),
            for: indexPath
        ) as! ProfileCell
        cell.update(with: cellViewModel)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        presenter?.didSelectContentForIndex(section: indexPath.section, row: indexPath.row)
    }
    
    private func moveAndResizeImage(for height: CGFloat) {
        let coeff: CGFloat = {
            let delta = height - ViewComponentConstants.NavBarHeightSmallState
            let heightDifferenceBetweenStates = (ViewComponentConstants.NavBarHeightLargeState - ViewComponentConstants.NavBarHeightSmallState)
            return delta / heightDifferenceBetweenStates
        }()

        let factor = ViewComponentConstants.ImageSizeForSmallState / ViewComponentConstants.ImageSizeForLargeState

        let scale: CGFloat = {
            let sizeAddendumFactor = coeff * (1.0 - factor)
            return min(1.0, sizeAddendumFactor + factor)
        }()

        // Value of difference between icons for large and small states
        let sizeDiff = ViewComponentConstants.ImageSizeForLargeState * (1.0 - factor) // 8.0

        let yTranslation: CGFloat = {
            /// This value = 14. It equals to difference of 12 and 6 (bottom margin for large and small states). Also it adds 8.0 (size difference when the image gets smaller size)
            let maxYTranslation = ViewComponentConstants.ImageBottomMarginForLargeState - ViewComponentConstants.ImageBottomMarginForSmallState + sizeDiff
            return max(0, min(maxYTranslation, (maxYTranslation - coeff * (ViewComponentConstants.ImageBottomMarginForSmallState + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)

        avatarImageView.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation, y: yTranslation)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        moveAndResizeImage(for: height)
    }
}

