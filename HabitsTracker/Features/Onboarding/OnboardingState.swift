import Foundation

enum OnboardingState: String {
    case pending
    case completed

    static func resolved(storedValue: String, hasExistingData: Bool) -> OnboardingState {
        if let stored = OnboardingState(rawValue: storedValue) {
            return stored
        }

        return hasExistingData ? .completed : .pending
    }
}
