//
//  EmotionalBundleCoordinator.swift
//  Soulverse
//

import UIKit

final class EmotionalBundleCoordinator {

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let service: EmotionalBundleServiceProtocol
    private let uid: String
    private var presenter: EmotionalBundleMainPresenter!

    /// Self-retention to prevent deallocation during the flow
    private var strongSelf: EmotionalBundleCoordinator?

    /// Called when the emotional bundle flow is dismissed
    var onDismiss: (() -> Void)?

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        uid: String,
        service: EmotionalBundleServiceProtocol = FirestoreEmotionalBundleService.shared
    ) {
        self.navigationController = navigationController
        self.uid = uid
        self.service = service
        // Retain self to prevent deallocation
        self.strongSelf = self
    }

    // MARK: - Public Methods

    func start() {
        let mainVC = EmotionalBundleMainViewController()
        let mainPresenter = EmotionalBundleMainPresenter(uid: uid, service: service)

        mainVC.presenter = mainPresenter
        mainVC.delegate = self
        mainPresenter.delegate = mainVC

        self.presenter = mainPresenter

        navigationController.pushViewController(mainVC, animated: true)
    }

    // MARK: - Private Methods

    private func cleanup() {
        strongSelf = nil
    }

    private func saveSection(_ section: EmotionalBundleSection, data: EmotionalBundleSectionData) {
        service.saveSection(uid: uid, section: section, data: data) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    self.navigationController.popViewController(animated: true)
                    self.presenter.refreshAfterSave()
                case .failure(let error):
                    debugPrint("[EmotionalBundle] Save failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - EmotionalBundleMainViewControllerDelegate

extension EmotionalBundleCoordinator: EmotionalBundleMainViewControllerDelegate {

    func didSelectSection(_ viewController: EmotionalBundleMainViewController, section: EmotionalBundleSection) {
        let bundle = presenter.currentBundle()

        switch section {
        case .redFlags:
            let vm = RedFlagsSectionViewModel(from: bundle.redFlags)
            let vc = RedFlagsSectionViewController(viewModel: vm)
            vc.delegate = self
            navigationController.pushViewController(vc, animated: true)

        case .supportMe:
            let vm = SupportMeSectionViewModel(from: bundle.supportMe)
            let vc = SupportMeSectionViewController(viewModel: vm)
            vc.delegate = self
            navigationController.pushViewController(vc, animated: true)

        case .feelCalm:
            let vm = FeelCalmSectionViewModel(from: bundle.feelCalm)
            let vc = FeelCalmSectionViewController(viewModel: vm)
            vc.delegate = self
            navigationController.pushViewController(vc, animated: true)

        case .staySafe:
            let vm = StaySafeSectionViewModel(from: bundle.staySafe)
            let vc = StaySafeSectionViewController(viewModel: vm)
            vc.delegate = self
            navigationController.pushViewController(vc, animated: true)

        case .professionalSupport:
            let vm = ProfessionalSupportSectionViewModel(from: bundle.professionalSupport)
            let vc = ProfessionalSupportSectionViewController(viewModel: vm)
            vc.delegate = self
            navigationController.pushViewController(vc, animated: true)
        }
    }

    func didTapClose(_ viewController: EmotionalBundleMainViewController) {
        navigationController.popViewController(animated: true)
        onDismiss?()
        cleanup()
    }
}

// MARK: - RedFlagsSectionViewControllerDelegate

extension EmotionalBundleCoordinator: RedFlagsSectionViewControllerDelegate {

    func didTapSave(_ viewController: RedFlagsSectionViewController, data: EmotionalBundleSectionData) {
        saveSection(.redFlags, data: data)
    }

    func didTapCancel(_ viewController: RedFlagsSectionViewController) {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - SupportMeSectionViewControllerDelegate

extension EmotionalBundleCoordinator: SupportMeSectionViewControllerDelegate {

    func didTapSave(_ viewController: SupportMeSectionViewController, data: EmotionalBundleSectionData) {
        saveSection(.supportMe, data: data)
    }

    func didTapCancel(_ viewController: SupportMeSectionViewController) {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - FeelCalmSectionViewControllerDelegate

extension EmotionalBundleCoordinator: FeelCalmSectionViewControllerDelegate {

    func didTapSave(_ viewController: FeelCalmSectionViewController, data: EmotionalBundleSectionData) {
        saveSection(.feelCalm, data: data)
    }

    func didTapCancel(_ viewController: FeelCalmSectionViewController) {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - StaySafeSectionViewControllerDelegate

extension EmotionalBundleCoordinator: StaySafeSectionViewControllerDelegate {

    func didTapSave(_ viewController: StaySafeSectionViewController, data: EmotionalBundleSectionData) {
        saveSection(.staySafe, data: data)
    }

    func didTapCancel(_ viewController: StaySafeSectionViewController) {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - ProfessionalSupportSectionViewControllerDelegate

extension EmotionalBundleCoordinator: ProfessionalSupportSectionViewControllerDelegate {

    func didTapSave(_ viewController: ProfessionalSupportSectionViewController, data: EmotionalBundleSectionData) {
        saveSection(.professionalSupport, data: data)
    }

    func didTapCancel(_ viewController: ProfessionalSupportSectionViewController) {
        navigationController.popViewController(animated: true)
    }
}
