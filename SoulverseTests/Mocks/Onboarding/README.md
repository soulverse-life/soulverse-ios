# Onboarding Mock Services

This directory contains mock implementations of onboarding services for **unit testing**.

## Files

- `MockOnboardingAuthenticationService.swift` - Mock authentication for testing
- `MockOnboardingDataService.swift` - Mock data submission for testing
- `MockOnboardingSessionService.swift` - Mock session management for testing

## Usage in Tests

```swift
import XCTest
@testable import Soulverse

class OnboardingCoordinatorTests: XCTestCase {

    func testSuccessfulOnboarding() {
        let mockAuth = MockOnboardingAuthenticationService(sessionService: sessionService)
        let mockData = MockOnboardingDataService()
        let mockSession = MockOnboardingSessionService()

        let coordinator = OnboardingCoordinator(
            navigationController: navigationController,
            authenticationService: mockAuth,
            dataService: mockData,
            sessionService: mockSession
        )

        // Test coordinator behavior...
    }
}
```

## UI Testing

For UI testing in the main app, use `OnboardingServiceFactory` instead:

```swift
// In SceneDelegate or wherever you need to test UI
#if DEBUG
OnboardingServiceFactory.shared.useMockServices = true
#endif
```

The factory will automatically provide debug implementations when `useMockServices` is `true`.
