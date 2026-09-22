// App/UmaApp.swift — @main entry point

import SwiftUI

@main
struct UmaApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(env)
                .preferredColorScheme(env.themeMode.colorScheme)
                .task {
                    env.loadBundles()
                }
        }
    }
}

extension ThemeService.Mode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
