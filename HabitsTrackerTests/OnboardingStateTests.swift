import XCTest
@testable import HabitsTracker

final class OnboardingStateTests: XCTestCase {
    func testFreshInstallStartsOnboarding() {
        XCTAssertEqual(
            OnboardingState.resolved(storedValue: "", hasExistingData: false),
            .pending
        )
    }

    func testExistingInstallIsGrandfatheredPastOnboarding() {
        XCTAssertEqual(
            OnboardingState.resolved(storedValue: "", hasExistingData: true),
            .completed
        )
    }

    func testInterruptedOnboardingRemainsPendingAfterDataIsSeeded() {
        XCTAssertEqual(
            OnboardingState.resolved(
                storedValue: OnboardingState.pending.rawValue,
                hasExistingData: true
            ),
            .pending
        )
    }
}
