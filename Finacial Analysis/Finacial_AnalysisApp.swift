//
//  Finacial_AnalysisApp.swift
//  Finacial Analysis
//
//  Created by Asher Antrim on 12/20/24.
//

import SwiftUI

@main
struct Finacial_AnalysisApp: App {
    @StateObject var watchlist = WatchlistManager()
        @StateObject var settings = SettingsManager()
        
        var body: some Scene {
            WindowGroup {
                TabView {
                    ContentView()
                        .tabItem {
                            Label("Analyze", systemImage: "magnifyingglass")
                        }
                        .environmentObject(watchlist)
                        .environmentObject(settings)
                    
                    NavigationView {
                        WatchlistView()
                            .environmentObject(watchlist)
                    }
                    .tabItem {
                        Label("Watchlist", systemImage: "star")
                    }
                    
                    NavigationView {
                        SettingsView()
                            .environmentObject(settings)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                .onAppear {
                    // Apply theme settings if needed
                }
            }
        }
    }
