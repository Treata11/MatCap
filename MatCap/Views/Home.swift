/*
 Home.swift
 MatCap

 Created by Treata Norouzi on 2/16/25.
*/

import SwiftUI
import SwiftData

struct Home: View {
    @Bindable var dataModel: DataModel
    
    @Environment(\.modelContext) private var modelContext
    @Query private var materials: [PBMaterial]
    
    var body: some View {
        materialGrid
    }
    
    var materialGrid: some View {
        NavigationStack {
            GeometryReader { geometry in
                let count = Int(geometry.size.width / 200)
                ScrollView(.vertical) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 150, maximum: 450)), count: count), spacing: 8) {
                        // Reveresed the items (to have the most recent ones on top)
                        //                    ForEach(musicLibrary.tracks.reversed()) { track in
                        //                        Albums(library: musicLibrary, playerModel: playerModel, track: track)
                        //                            .padding(.bottom)
                        //                            .padding(.horizontal, 6.25)
                        //                    }
                        
                        //                    Group {
                        //                        ARPreviewContainer(baseColor: UIImage(resource: .example).pngData(), normalMap: UIImage(resource: .exampleNormal).pngData(), roughnessMap: UIImage(resource: .exampleRoughness).pngData())
                        //                        ARPreviewContainer(baseColor: UIImage(resource: .brick).pngData(), normalMap: UIImage(resource: .brickNormal).pngData(), roughnessMap: UIImage(resource: .brickRoughness).pngData())
                        //                        ARPreviewContainer(radius: 0.66)
                        //                        ARPreviewContainer(radius: 0.66)
                        //                        ARPreviewContainer(radius: 0.66)
                        //                        ARPreviewContainer(radius: 0.66)
                        //                        ARPreviewContainer(radius: 0.66)
                        //                    }
                        Group {
                            ForEach(materials) { material in
                                NavigationLink(destination: MaterialInfoTab(material: material), label: {
                                    VStack(alignment: .leading) {
                                        ARPreviewContainer(baseColor: material.baseColor, normalMap: material.normalMap, roughnessMap: material.roughnessMap)
                                            .clipShape(.rect(cornerRadius: 12))
                                        Text(material.name)
                                            .foregroundStyle(Color.primary)
                                    }
                                    .padding(.bottom)
                                })
                            }
                            materialAddition
                        }
                        .frame(minWidth: 200, minHeight: 200)
                        .onAppear {
                            print(materials.count)
                            print(geometry.size.width)
                        }
                    }
                    .padding()
                }
            }
        }
        .environment(dataModel)
//            .modelContainer(appContainer)
    }
    
//    @Environment(\.editMode) private var editMode
    @State private var isPresented = false
    
    var materialAddition: some View {
        Button(action: {
            isPresented = true
        }, label: {
            VStack(alignment: .leading) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(Color.black)
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .foregroundStyle(Color.accentColor)
                }
                
                Text("Add New Material")
                    .foregroundStyle(Color.primary)
            }
        })
        .sheet(isPresented: $isPresented) {
            CreateMaterialView(dataModel: dataModel)
        }
    }
}

#Preview {
    Home(dataModel: DataModel())
        .modelContainer(appContainer)
}

// TODO: New File -

// TODO: Introduce edit mode
struct MaterialInfoTab: View {
    @Environment(DataModel.self) private var dataModel
    
    var material: PBMaterial
    var mesh: BasicMesh = .sphere
//    var spacerLength: CGFloat = 35
    
    var body: some View {
        GeometryReader {
            let size = $0.size
//            let safeAreaInsets = $0.safeAreaInsets
            let spacerLength = min(size.width, size.height) / 10
            let halfLength = spacerLength/2
//            let rendererBounds = size.width * 9/10
            
            NavigationStack {
                ScrollView(.vertical) {
                    VStack(alignment: .center) {
//                        Text(material.name)
//                            .font(.largeTitle)
//                            .multilineTextAlignment(.leading)
                        ARPreviewContainer(radius: 0.8, baseMesh: mesh, baseColor: material.baseColor, normalMap: material.normalMap, roughnessMap: material.roughnessMap)
                            .frame(width: size.width, height: size.width)
                        
                        Spacer(minLength: spacerLength)
                        
                        VStack(alignment: .leading) {
                            Text("Base Color Texture").font(.title2)
                            textureView(from: material.baseColor, width: size.width)
                            
                            Spacer(minLength: halfLength)
                            
                            Text("Normal Map Texture").font(.title2)
                            textureView(from: material.normalMap, width: size.width)
                            
                            Spacer(minLength: halfLength)
                            
                            Text("Roughness Map Texure").font(.title2)
                            textureView(from: material.roughnessMap, width: size.width)
                            
                            Spacer(minLength: halfLength)
                            
                            Text("Displacement Map Texure").font(.title2)
                            textureView(from: material.displacementMap, width: size.width)
                            
                            Spacer(minLength: spacerLength)
                            
                            processButton
                            
                            Spacer(minLength: spacerLength*2)
                        }
                        .padding(.bottom)
                    }
                    .padding()
                }
                .frame(width: size.width)
                .navigationTitle(material.name)
                .navigationBarTitleDisplayMode(.large)
                .allowsTightening(.random())
            }
        }
        .ignoresSafeArea(edges: .horizontal)
    }
    
    var processButton: some View {
        Button(action: {
            Task {
                try await dataModel.process(image: UIImage(data: material.baseColor))
                
                material.normalMap = dataModel.normalCGImage?.png
                material.roughnessMap = dataModel.roughnessCGImage?.png
                material.displacementMap = dataModel.displacementCGImage?.png
            }
        }, label: {
            Text("Process Base Color Texture")
                .font(.headline)
                .padding()
                .background(Capsule().stroke(lineWidth: 3))
        })
    }
}

@ViewBuilder
func textureView(from data: Data?, width: CGFloat) -> some View {
    if let data = data {
        let uiImage: UIImage = UIImage(data: data) ?? UIImage()
        let bounds = width * 3/4
        
        Image(uiImage: uiImage)
            .resizable()
            .clipShape(.rect(cornerRadius: 6))
            .frame(width: bounds, height: bounds)
        
        let dimension = Int(uiImage.size.width)
        Text("Dimensions: \(dimension) x \(dimension)")
        if let colorSpace = uiImage.colorSpace, let name = colorSpace.name {
            Text("Color Space: \(name.trimmedColorSpacePrefix)")
        }
    } else {
        loadingTextureProgressView(width: width)
    }
}

@ViewBuilder
func textureView(from data: Data, width: CGFloat) -> some View {
    let uiImage: UIImage = UIImage(data: data) ?? UIImage()
    let bounds = width * 3/4
    
    Image(uiImage: uiImage)
        .resizable()
        .clipShape(.rect(cornerRadius: 6))
        .frame(width: bounds, height: bounds)
    
    let dimension = Int(uiImage.size.width)
    Text("Dimensions: \(dimension) x \(dimension)")
    if let colorSpace = uiImage.colorSpace, let name = colorSpace.name {
        Text("Color Space: \(name.trimmedColorSpacePrefix)")
    }
}

@ViewBuilder
func loadingTextureProgressView(width: CGFloat) -> some View {
    let bounds = width * 3/4
    
    ProgressView()
        .font(.largeTitle)
        .frame(width: bounds, height: bounds)
    // TODO: Process
}

#Preview("MaterialInfoTab") {
    MaterialInfoTab(material: brick)
        .environment(DataModel())
}

func createImage(_ value: Data) -> Image {
#if canImport(UIKit)
    let songArtwork: UIImage = UIImage(data: value) ?? UIImage()
    return Image(uiImage: songArtwork).resizable()
#elseif canImport(AppKit)
    let songArtwork: NSImage = NSImage(data: value) ?? NSImage()
    return Image(nsImage: songArtwork).resizable()
#else
    return Image(systemImage: "some_default")
#endif
}

extension UIImage {
    var colorSpace: CGColorSpace? {
        if let cgImage = self.cgImage {
            return cgImage.colorSpace
        } else {
            return nil
        }
    }
}

extension CFString {
    var trimmedColorSpacePrefix: String {
        let prefix = "kCGColorSpace"
        let string = self as String
        
        // Check if the string has the prefix and trim it if it does
        if string.hasPrefix(prefix) {
            let trimmedString = String(string.dropFirst(prefix.count))
            return trimmedString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Return the original string if it doesn't have the prefix
        return string
    }
}

