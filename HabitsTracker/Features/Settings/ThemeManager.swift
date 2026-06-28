import SwiftUI
import Combine
import DesignKit

@MainActor
final class ThemeManager: ObservableObject {
    @Published var mode: ThemeMode {
        didSet { designKitManager.mode = mode }
    }

    @Published var preset: ThemePreset {
        didSet { designKitManager.preset = preset }
    }

    private let designKitManager: DKThemeManager

    init() {
        let manager = DKThemeManager()
        self.designKitManager = manager
        self.mode = manager.mode
        self.preset = manager.preset
    }

    func theme(for colorScheme: ColorScheme) -> Theme {
        designKitManager.mode = mode
        designKitManager.preset = preset
        return designKitManager.theme(using: colorScheme)
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
