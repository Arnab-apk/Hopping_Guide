// App/AppRoot.swift — root shell + tab navigation with Puja icons

import SwiftUI

struct AppRoot: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        if !env.hasOnboarded {
            WelcomeView()
        } else {
            TabView(selection: tabBinding) {
                MapTabView()
                    .tabItem {
                        Label("Map", image: "durga_eyes")
                    }
                    .tag(AppTab.map)

                PandalsListView()
                    .tabItem {
                        Label("Pandals", image: "durga_face")
                    }
                    .tag(AppTab.pandals)

                RoutesView()
                    .tabItem {
                        Label("Routes", image: "ashtabhuja_variant")
                    }
                    .tag(AppTab.routes)

                SquadHubView()
                    .tabItem {
                        Label("Squads", image: "dhaki")
                    }
                    .tag(AppTab.squads)

                HelplinesView()
                    .tabItem {
                        Label("Helpline", image: "trishul_eyes")
                    }
                    .tag(AppTab.helplines)
            }
            .tint(PujaColors.durgaRed)
        }
    }

    private var tabBinding: Binding<AppTab> {
        Binding(
            get: { env.selectedTab },
            set: { env.selectedTab = $0 }
        )
    }
}

#Preview {
    AppRoot()
        .environment(AppEnvironment())
}
