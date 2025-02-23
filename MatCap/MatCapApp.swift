/*
 MatCapApp.swift
 MatCap

 Created by Treata Norouzi on 2/6/25.
 
 Abstract:
 Material Capture App
*/

import SwiftUI
import SwiftData

/// Size of the textures `256 by 256`
//let targetSize = CGSize(width: 256, height: 256)

@main
struct MatCapApp: App {
    @Bindable var dataModel = DataModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PBMaterial.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // Migrate to `DocumentGroup`?
        WindowGroup {
//            ContentView()
//            CameraView()
//            TestsView()
            Home()
                .modelContainer(sharedModelContainer)
        }
        .environment(dataModel)
    }
}
