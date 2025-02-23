//
//  Item.swift
//  MatCap
//
//  Created by Treata Norouzi on 2/6/25.
//

import Foundation
import SwiftData

@Model
class PBMaterial: Identifiable {
    var name: String
    
    // TODO: merge id with name...
    @Attribute(.unique) var id: String = UUID().uuidString
    
    /// The `Albedo` texutre
    @Attribute(.externalStorage) var baseColor: Data
    @Attribute(.externalStorage) var normalMap: Data?
    @Attribute(.externalStorage) var roughnessMap: Data?
    @Attribute(.externalStorage) var displacementMap: Data?
    
    // TODO: A snap shot variable
//    @Attribute(.externalStorage) var snapshot: Data?
    
    init(name: String, baseColor: Data,
         normalMap: Data? = nil, roughnessMap: Data? = nil, displacementMap: Data? = nil
    ) {
        self.baseColor = baseColor
        self.name = name
        self.normalMap = normalMap
        self.roughnessMap = roughnessMap
        self.displacementMap = displacementMap
    }
}


@Model
final private class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

// MARK: - 

import SwiftUI

// https://www.andrewcbancroft.com/blog/ios-development/data-persistence/pre-populate-swiftdata-persistent-store/
@MainActor
let appContainer: ModelContainer = {
    do {
        let container = try ModelContainer(for: PBMaterial.self)
        
        // Use correct FetchDescriptor for PBMaterial
        var materialFetchDescriptor = FetchDescriptor<PBMaterial>()
        materialFetchDescriptor.fetchLimit = 1
        
        // Check if any materials exist
        let existingMaterials = try container.mainContext.fetch(materialFetchDescriptor)
        
        if existingMaterials.isEmpty {
            // Create preset materials
            let metalSheet = PBMaterial(
                name: "Galvanized Metal Sheet",
                baseColor: (UIImage(named: "MetalGrate")?.pngData())!,
                normalMap: UIImage(named: "MetalGrate_Normal")?.pngData(),
                roughnessMap: UIImage(named: "MetalGrate_Roughness")?.pngData(),
                displacementMap: UIImage(named: "MetalGrate_Displacement")?.pngData()
            )
            let brick = PBMaterial(
                name: "Brick",
                baseColor: (UIImage(named: "Brick")?.pngData())!,
                normalMap: UIImage(named: "Brick_Normal")?.pngData(),
                roughnessMap: UIImage(named: "Brick_Roughness")?.pngData(),
                displacementMap: UIImage(named: "Brick_Displacement")?.pngData()
            )
            
            let materials: [PBMaterial] = [metalSheet, brick]
            
            // Insert materials
            for material in materials {
                container.mainContext.insert(material)
            }
            
            // Save the context
            try container.mainContext.save()
            
            print("Added preset PBMaterials to container: \(container)")
        }
        
        return container
    } catch {
        fatalError("Failed to create container: \(error)")
    }
}()
