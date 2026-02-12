//
//  ProfileViewController.swift
//  Soulverse
//

import SnapKit
import UIKit

class ProfileViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let sectionSpacing: CGFloat = 32
        static let rowSpacing: CGFloat = 16
        static let labelSpacing: CGFloat = 4
        static let buttonSpacing: CGFloat = 16
        static let deleteButtonTopSpacing: CGFloat = 24
    }

    // MARK: - Properties

    private let presenter = ProfileViewPresenter()

    // MARK: - UI Components

    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("profile_title", comment: ""),
            showBackButton: true
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.sectionSpacing
        stackView.alignment = .fill
        return stackView
    }()

    // User Info Section
    private lazy var userInfoSection: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.rowSpacing
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var nameRow: ProfileInfoRow = {
        let row = ProfileInfoRow()
        row.configure(
            label: NSLocalizedString("profile_name_label", comment: ""),
            value: nil
        )
        return row
    }()

    private lazy var emailRow: ProfileInfoRow = {
        let row = ProfileInfoRow()
        row.configure(
            label: NSLocalizedString("profile_email_label", comment: ""),
            value: nil
        )
        return row
    }()

    private lazy var authProviderRow: ProfileInfoRow = {
        let row = ProfileInfoRow()
        row.configure(
            label: NSLocalizedString("profile_auth_provider_label", comment: ""),
            value: nil
        )
        return row
    }()

    private lazy var emoPetRow: ProfileInfoRow = {
        let row = ProfileInfoRow()
        row.configure(
            label: NSLocalizedString("profile_emopet_label", comment: ""),
            value: nil
        )
        return row
    }()

    private lazy var planetRow: ProfileInfoRow = {
        let row = ProfileInfoRow()
        row.configure(
            label: NSLocalizedString("profile_planet_label", comment: ""),
            value: nil
        )
        return row
    }()

    // Action Buttons Section
    private lazy var buttonSection: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.buttonSpacing
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var logoutButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("profile_logout_button", comment: ""),
            style: .primary,
            delegate: self
        )
        return button
    }()

    private lazy var deleteAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(
            NSLocalizedString("profile_delete_account_button", comment: ""),
            for: .normal
        )
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPresenter()
        presenter.fetchProfile()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil

        view.addSubview(navigationView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // User info section
        userInfoSection.addArrangedSubview(nameRow)
        userInfoSection.addArrangedSubview(emailRow)
        userInfoSection.addArrangedSubview(authProviderRow)
        userInfoSection.addArrangedSubview(emoPetRow)
        userInfoSection.addArrangedSubview(planetRow)

        // Button section
        buttonSection.addArrangedSubview(logoutButton)

        // Content stack
        contentStackView.addArrangedSubview(userInfoSection)
        contentStackView.addArrangedSubview(buttonSection)
        contentStackView.addArrangedSubview(deleteAccountButton)

        // Constraints
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.width.equalTo(scrollView).offset(-ViewComponentConstants.horizontalPadding * 2)
        }

        logoutButton.snp.makeConstraints { make in
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        deleteAccountButton.snp.makeConstraints { make in
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupPresenter() {
        presenter.delegate = self
    }

    private func configure(with viewModel: ProfileViewModel) {
        nameRow.configure(
            label: NSLocalizedString("profile_name_label", comment: ""),
            value: viewModel.userName
        )
        emailRow.configure(
            label: NSLocalizedString("profile_email_label", comment: ""),
            value: viewModel.email
        )
        authProviderRow.configure(
            label: NSLocalizedString("profile_auth_provider_label", comment: ""),
            value: viewModel.authProvider
        )
        emoPetRow.configure(
            label: NSLocalizedString("profile_emopet_label", comment: ""),
            value: viewModel.emoPetName
        )
        planetRow.configure(
            label: NSLocalizedString("profile_planet_label", comment: ""),
            value: viewModel.planetName
        )

        logoutButton.isEnabled = !viewModel.isLoading
        deleteAccountButton.isEnabled = !viewModel.isLoading
    }

    // MARK: - Actions

    @objc private func deleteAccountTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("profile_delete_confirm_title", comment: ""),
            message: NSLocalizedString("profile_delete_confirm_message", comment: ""),
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(
            title: NSLocalizedString("profile_delete_account_button", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            self?.presenter.deleteAccount()
        }

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("cancel", comment: ""),
            style: .cancel
        )

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func showLogoutConfirmation() {
        let alert = UIAlertController(
            title: NSLocalizedString("profile_logout_confirm_title", comment: ""),
            message: NSLocalizedString("profile_logout_confirm_message", comment: ""),
            preferredStyle: .alert
        )

        let logoutAction = UIAlertAction(
            title: NSLocalizedString("profile_logout_button", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            self?.presenter.logout()
        }

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("cancel", comment: ""),
            style: .cancel
        )

        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func transitionToOnboarding() {
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        sceneDelegate.transitionToOnboarding()
    }
}

// MARK: - ProfileViewPresenterDelegate

extension ProfileViewController: ProfileViewPresenterDelegate {

    func didUpdate(viewModel: ProfileViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showLoading = viewModel.isLoading
            self.configure(with: viewModel)
        }
    }

    func didLogout() {
        DispatchQueue.main.async { [weak self] in
            self?.transitionToOnboarding()
        }
    }

    func didDeleteAccount() {
        DispatchQueue.main.async { [weak self] in
            self?.transitionToOnboarding()
        }
    }

    func didFailWithError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: nil,
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("spiral_alert_button", comment: ""),
                style: .default
            ))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension ProfileViewController: SoulverseButtonDelegate {

    func clickSoulverseButton(_ button: SoulverseButton) {
        if button === logoutButton {
            showLogoutConfirmation()
        }
    }
}

