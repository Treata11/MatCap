//
//  RealityKitTests.swift
//  MatCap
//
//  Created by Treata Norouzi on 2/9/25.
//
// Applying Texture maps to a mesh


#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create an ARView
        arView = ARView(frame: self.view.bounds)
        self.view.addSubview(arView)
        
        // Load a basic box model
        let boxMesh = MeshResource.generateBox(size: 0.2)
        
        // Create a material
        var material = UnlitMaterial()
        
        // Load textures
        let normalTexture = try! TextureResource.load(named: "normal_map")
        let roughnessTexture = try! TextureResource.load(named: "roughness_map")
        
        // Set the textures to the material
//        material.normalTexture = normalTexture
//        material.roughnessTexture = roughnessTexture
        
        // Create a model entity with the mesh and material
        let modelEntity = ModelEntity(mesh: boxMesh, materials: [material])
        
        // Create an anchor entity
        let anchorEntity = AnchorEntity(plane: .horizontal)
        anchorEntity.addChild(modelEntity)
        
        // Add the anchor entity to the scene
        arView.scene.addAnchor(anchorEntity)
    }
}

#endif
