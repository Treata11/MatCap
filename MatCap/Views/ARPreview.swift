
//
//  ContentView.swift
//  RealityKit-iOSTests
//
//  Created by Treata Norouzi on 1/27/24.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)

import SwiftUI
import RealityKit
import ARKit

//struct ContentView : View {
//    var body: some View {
//        ARViewContainer().edgesIgnoringSafeArea(.all)
//    }
//}

private struct ARViewContainer: UIViewRepresentable {
    /*
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)

        // Create a cube model
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.05

        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model)

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
     */
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // Disable automatic AR configuration
        arView.automaticallyConfigureSession = false
        // Comment out the following lines to render on-Screen
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)
        
        // Create a cube model
//        let mesh = MeshResource.generateBox(size: 0.5, cornerRadius: 0.005)
        let mesh = MeshResource.generateSphere(radius: 0.3)
        let material = SimpleMaterial(color: .yellow, roughness: 0.15, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.05

        // Create an anchor for the content
        let anchor = AnchorEntity()
        anchor.children.append(model)
        
        // Add the anchor to the scene
        arView.scene.anchors.append(anchor)
        //
        
        return arView
    }
    
    // https://stackoverflow.com/questions/59078633/programmatically-setting-texture-in-scene-generated-by-reality-composer
//    func makeUIView(context: Context) -> ARView {
//        let arView = ARView(frame: .zero)
//        // Comment out the following lines to render on-Screen
//        // Disable automatic AR configuration
//        arView.automaticallyConfigureSession = false
//        // Comment out the following lines to render on-Screen
//        let config = ARWorldTrackingConfiguration()
//        arView.session.run(config)
//        
//        // Create a cube model
//        let mesh = MeshResource.generateBox(size: 0.5, cornerRadius: 0.005)
//
//        let model = ModelEntity(mesh: mesh)
//        model.transform.translation.y = 0.05
//
//        // Create an anchor for the content
//        let anchor = AnchorEntity()
//        anchor.children.append(model)
//        model.scale = SIMD3(x: 9, y: 9, z: 9)
//        model.orientation = simd_quatf(angle: -Float.pi/4,
//                                       axis: SIMD3(x: 1, y: 1, z: 0))
//
//        var boxComponent: ModelComponent = model.components[ModelComponent].self!
//
//        let paths: NSArray = NSSearchPathForDirectoriesInDomains(.documentDirectory,
//                                                                 .userDomainMask,
//                                                                  true) as NSArray
//
//
//
//        let url = Bundle.main.url(forResource: "example", withExtension: "png")
//        print(url)
//
//        var material = SimpleMaterial()
//        material.color = .init(tint: .yellow)
//        if let url = url {
//            material.baseColor = try! MaterialColorParameter.texture(TextureResource.load(contentsOf: url))
//        }
//        material.roughness = MaterialScalarParameter(floatLiteral: 0.1)
//        material.metallic = MaterialScalarParameter(floatLiteral: 0.1)
//        boxComponent.materials = [material]
//        
//
//        model.components.set(boxComponent)
//        anchor.addChild(model)
////        anchor.addChild(boxComponent)
//        // Add the anchor to the scene
//        arView.scene.anchors.append(anchor)
//        
//        return arView
//    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

//#Preview {
//    ContentView()
//}

#Preview {
    ARViewContainer().ignoresSafeArea()
}


// MARK: - main

//
//  ARPreview.swift
//  RealityKit-iOSTests
//
//  Created by Treata Norouzi on 1/28/24.
//

import SwiftUI
import RealityKit
import ARKit

/*
// Load the USDZ file and add it to the scene
if let usdzModel = try? Entity.loadModel(named: "yourModel.usdz") {
    let anchorEntity = AnchorEntity()
    anchorEntity.addChild(usdzModel)
    arView.scene.addAnchor(anchorEntity)
}
 */

// Main
struct ARPreviewContainer: UIViewRepresentable {
    var radius: Float = 0.666
    var baseMesh: BasicMesh = .sphere
    
    // TODO: Convert the following to @Binding
    var baseColor: Data?
    var normalMap: Data?
    var roughnessMap: Data?
    var ambientOcclusion: Data?
    
    @Binding var goAR: Bool
    
    init(radius: Float = 0.6667, baseMesh: BasicMesh = .sphere,
         goAR: Binding<Bool> = .constant(false),
         baseColor: Data? = nil,
         normalMap: Data? = nil,
         roughnessMap: Data? = nil,
         ambientOcclusion: Data? = nil) {
        self.radius = radius
        self.baseMesh = baseMesh
        self._goAR = goAR
        self.baseColor = baseColor
        self.normalMap = normalMap
        self.roughnessMap = roughnessMap
        self.ambientOcclusion = ambientOcclusion
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // Disable automatic AR configuration
        arView.automaticallyConfigureSession = goAR

        if goAR {
            #if !targetEnvironment(simulator)
            if !ProcessInfo.processInfo.isiOSAppOnMac {
                let config = ARWorldTrackingConfiguration()
                arView.session.run(config)
            }
            #endif
        }
//        arView.renderOptions = []
        
        let mesh = baseMesh == .cube ? MeshResource.generateBox(size: radius*2, cornerRadius: radius) : MeshResource.generateSphere(radius: radius)
        
        
        // Load the texture from the asset bundle
//        guard let textureURL = Bundle.main.url(forResource: "example", withExtension: "png"),
//             let texture = try? TextureResource.load(contentsOf: textureURL) else {
//            print("Failed to load texture"); fatalError()
//        }
       
       // Create a material with the loaded texture
//       var textureMaterial = SimpleMaterial()
//       material.baseColor = MaterialColorParameter.texture(textureMaterial)

        
//        var simpleMaterial = SimpleMaterial()
//        simpleMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
//                               texture: MaterialParameters.Texture(try! .load(named: "example", in: .main)))
        
        
//        let pbrMaterial = Self.generateMaterialFromImages(baseColor: "example", normal: "example_Normal", roughness: "example_Roughness", ambientOcclusion: "example_Displacement")
        let pbrMaterial = setPBRMaterial()
        
        let model = ModelEntity(mesh: mesh, materials: [pbrMaterial])

        let anchorEntity = AnchorEntity()
        anchorEntity.name = "PreviewAnchor"
        anchorEntity.addChild(model)
        arView.scene.addAnchor(anchorEntity)
        
        addLightning(to: arView)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Update the view here if needed
    }
    
    // iOS 18
    func setPBRMaterial(uiColor: UIColor? = nil, enableClearCoat: Bool = false) -> PhysicallyBasedMaterial {
        // TODO: Add influence
        var material = PhysicallyBasedMaterial()
        
        if let color = uiColor {
            material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: color)
        } else if let baseColor = self.baseColor, let image: CGImage = UIImage(data: baseColor, scale: 1)!.cgImage {
            let texture: TextureResource = try! .init(image: image, options: .init(semantic: .color))
            let baseColor = MaterialParameters.Texture(texture)
            material.baseColor = PhysicallyBasedMaterial.BaseColor(texture: baseColor)
        }
        
        if let normalMap = self.normalMap, let image: CGImage = UIImage(data: normalMap, scale: 1)!.cgImage {
            let nTexture: TextureResource = try! .init(image: image, options: .init(semantic: .normal))
            let normal = MaterialParameters.Texture(nTexture)
            material.normal = PhysicallyBasedMaterial.Normal(texture: normal)
        }
        if let roughnessMap = self.roughnessMap, let image: CGImage = UIImage(data: roughnessMap, scale: 1)!.cgImage {
            let rTexture: TextureResource = try! .init(image: image, options: .init(semantic: .scalar))
            let roughness = MaterialParameters.Texture(rTexture)
            material.roughness = PhysicallyBasedMaterial.Roughness(texture: roughness)
        }
        // TODO: Use displacement as `ambientOcclusion` map?
        
        material.blending = .opaque
        return material
    }
    
    /// Images must be from Bundle
    static func generateMaterialFromImages(
        uiColor: UIColor? = nil,
        baseColor: String? = nil,
        normal: String? = nil,
        roughness: String? = nil,
        ambientOcclusion: String? = nil,
        metallic: String? = nil,
        clearcoat: String? = nil,
        emissiveColor: String? = nil
    ) -> PhysicallyBasedMaterial {
            
        var material = PhysicallyBasedMaterial()
        
        if let color = uiColor {
            material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: color)
            
        } else if let resourceFileName = baseColor, let resource = try? TextureResource.load(named: resourceFileName) {
            let baseColor = MaterialParameters.Texture(resource)
            material.baseColor = PhysicallyBasedMaterial.BaseColor(texture: baseColor)
        }
        
        if let resourceFileName = normal, let resource = try? TextureResource.load(named: resourceFileName) {
            let normal = MaterialParameters.Texture(resource)
            material.normal = PhysicallyBasedMaterial.Normal(texture: normal)
        }
        if let resourceFileName = roughness, let resource = try? TextureResource.load(named: resourceFileName) {
            let roughness = MaterialParameters.Texture(resource)
            material.roughness = PhysicallyBasedMaterial.Roughness(texture: roughness)
        } else {
            print("Could not find Rougness Texture: \(String(describing: try? TextureResource.load(named: roughness!)))")
        }
        if let resourceFileName = ambientOcclusion, let resource = try? TextureResource.load(named: resourceFileName) {
            let ambientOcclusion = MaterialParameters.Texture(resource)
            material.ambientOcclusion = PhysicallyBasedMaterial.AmbientOcclusion(texture: ambientOcclusion)
        }
        if let resourceFileName = metallic, let resource = try? TextureResource.load(named: resourceFileName) {
            let metallic = MaterialParameters.Texture(resource)
            material.metallic = PhysicallyBasedMaterial.Metallic(texture: metallic)
        }
        if let resourceFileName = clearcoat, let resource = try? TextureResource.load(named: resourceFileName) {
            let clearcoat = MaterialParameters.Texture(resource)
            material.clearcoat = PhysicallyBasedMaterial.Clearcoat(texture: clearcoat)
        }
        if let resourceFileName = emissiveColor, let resource = try? TextureResource.load(named: resourceFileName) {
            let emissiveColor = MaterialParameters.Texture(resource)
            material.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(texture:emissiveColor)
        }
        
        material.blending = .opaque
        return material
    }
    
    private func addLightning(to arView: ARView) {
        // MARK: Lightning
        // Create an anchor entity for the light
        let lightAnchor = AnchorEntity(world: [0, -1, 5]) // Position the light above the model

        // Create a directional light component
        let directionalLightComponent = DirectionalLightComponent(color: .white, intensity: 10_000, isRealWorldProxy: true)
        let spotLightComponent = SpotLightComponent(color: .white, intensity: 10000, innerAngleInDegrees: -120, outerAngleInDegrees: 180, attenuationRadius: 1000_000)
        
        // Create a light entity and add the light component to it
        let directionalLightEntity = Entity()
        directionalLightEntity.components[DirectionalLightComponent.self] = directionalLightComponent
        let spotLightEntity = Entity()
        spotLightEntity.components[SpotLightComponent.self] = spotLightComponent
        
        // Add the light entity to the light anchor
//        lightAnchor.addChild(directionalLightEntity)
        lightAnchor.addChild(spotLightEntity)

        // (will not affect ARView's background)
        arView.backgroundColor = .white
        // Add the light anchor to the scene
        arView.scene.addAnchor(lightAnchor)
    }
}

enum BasicMesh {
    case cube
    case sphere
    case plane
}

struct ARPreview: View {
    var body: some View {
        ARPreviewContainer(baseColor: UIImage(resource: .brick).pngData(), normalMap: UIImage(resource: .brickNormal).pngData(), roughnessMap: UIImage(resource: .brickRoughness).pngData())
            .ignoresSafeArea(edges: .all)
            .background {
                Color.white
            }
    }
}

#Preview("ARPreview") {
    ARPreview()
}

#endif
