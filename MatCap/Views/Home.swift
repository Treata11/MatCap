/*
 Home.swift
 MatCap

 Created by Treata Norouzi on 2/16/25.
*/

import SwiftUI
import SwiftData

// FIXME: Auto referesh doesn't happen when a new material is added
struct Home: View {
//    @Bindable var dataModel: DataModel
    @Environment(DataModel.self) private var dataModel
    
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
                        Group {
                            let materials = materials.reversed()
                            ForEach(materials) { material in
                                NavigationLink(destination: MaterialInfoTab(material: material), label: {
                                    VStack(alignment: .leading) {
                                        ARPreviewContainer(baseColor: material.baseColor, normalMap: material.normalMap, roughnessMap: material.roughnessMap)
                                            .clipShape(.rect(cornerRadius: 12))
                                        Text(material.name)
                                            .foregroundStyle(Color.primary)
                                    }
                                    .padding(.bottom)
                                    // Delete a Material
                                    .overlay(alignment: .topLeading) {
                                        if isEditing {
                                            Button(action: {
                                                withAnimation(.easeOut(duration: 0.5)) {
                                                    modelContext.delete(material)
                                                }
                                                try? modelContext.save()
                                            }, label: {
                                                let offset = min(geometry.size.width, geometry.size.height) / -50
                                                
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.largeTitle)
                                                    .foregroundStyle(Color.red)
                                                    .offset(x: offset, y: offset)
                                            })
                                        }
                                    }
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
            .navigationTitle(Text("Physically Based Materials"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    editModeButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    // Duplicate as `materialAddition`
                    Button(action: {
                        isPresented = true
                        isEditing = false
                    }, label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    })
                }
            }
        }
        .environment(dataModel)
        // Preset container
        .modelContainer(appContainer)
    }
    
//    @Environment(\.editMode) private var editMode
    @State private var isPresented = false
    
    var materialAddition: some View {
        Button(action: {
            isPresented = true
            isEditing = false
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
            CreateMaterialView()
        }
    }
    
//    @Environment(\.editMode) private var editMode
    @State private var isEditing = false
    
    var editModeButton: some View {
        Button(action: {
            self.isEditing.toggle()
        }, label: {
            let title = isEditing ? "Done" : "Edit"
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
        })
    }
}

#Preview {
    Home()
        .environment(DataModel())
        .modelContainer(appContainer)
}


// TODO: New File -

import Photos

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
                            .overlay(alignment: .bottomTrailing) { arButton }
                        
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
                    .padding(.horizontal)
                    .fullScreenCover(isPresented: $goAR, onDismiss: {}) {
                        arPreview
                    }
                }
                .frame(width: size.width)
                .navigationTitle(material.name)
                .navigationBarTitleDisplayMode(.inline)
                .allowsTightening(.random())
                .toolbar {
                    // Exports the Textures to PhotosLibrary
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            // FIXME: Doesn't save
                            saveImagesToPhotoLibrary()
                        }, label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title3)
                                .padding()
                        })
                    }
                }
                .toolbarTitleDisplayMode(.automatic)
            }
        }
        .ignoresSafeArea(edges: .all)
//        .onAppear {
//            if material.displacementMap == nil {
//                process()
//            }
//        }
    }
    
    var processButton: some View {
        Button(action: {
            process()
        }, label: {
            Text("Process Base Color Texture")
                .font(.headline)
                .padding()
                .background(Capsule().stroke(lineWidth: 2))
                .shadow(radius: 18)
        })
    }
    
    private func process() {
//        dataModel.free()
        
        Task {
            let uiImage = UIImage(data: material.baseColor)
            try await dataModel.process(image: uiImage, orientation: uiImage?.imageOrientation ?? .up)
            
            withAnimation() {
                material.normalMap = dataModel.normalCGImage?.png
                material.roughnessMap = dataModel.roughnessCGImage?.png
                material.displacementMap = dataModel.displacementCGImage?.png
                    
            }
            
            provideFeedback(.success)
        }
    }
    
    @State private var goAR = false

    var arButton: some View {
        Button(action: {
            goAR = true
        }, label: {
            Text("AR")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(Color.accentColor)
                .shadow(color: .gray, radius: 12)
                .padding()
        })
        .padding()
    }
    
    var arPreview: some View {
        NavigationStack {
            ARPreviewContainer(radius: 0.1618, baseMesh: mesh, goAR: $goAR, baseColor: material.baseColor, normalMap: material.normalMap, roughnessMap: material.roughnessMap)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done", role: .cancel, action: {
                            self.goAR = false
                        })
                        .shadow(color: .gray, radius: 12)
                    }
                }
        }
        .ignoresSafeArea()
    }
    
    // MARK: Save Material to PhotosLibrary
    private func saveImagesToPhotoLibrary() {
        // Request authorization to access Photo Library
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo Library access denied")
                return
            }
            
            let name = material.name
            // Convert Data to UIImage
            guard let albedoImage = UIImage(data: material.baseColor) else {
                print("Failed to convert image data")
                return
            }
            saveImage(albedoImage, filename: "\(name)_Albedo")
            provideFeedback(.success)
            
            if let normalMap = material.normalMap, let normalImage = UIImage(data: normalMap) {
                saveImage(normalImage, filename: "\(name)_Normal")
            }
            
            if let roughnessMap = material.roughnessMap, let roughnessImage = UIImage(data: roughnessMap) {
                saveImage(roughnessImage, filename: "\(name)_Roughness")
            }
            
            if let displacementMap = material.displacementMap, let displacementImage = UIImage(data: displacementMap) {
                saveImage(displacementImage, filename: "\(name)_Displacement")
            }
        }
    }

    private func saveImage(_ image: UIImage, filename: String) {
        guard let imageData = image.pngData() else {
            print("Failed to convert image to PNG data")
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = filename // Set the filename here
            creationRequest.addResource(with: .photo, data: imageData, options: options)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Successfully saved \(filename)")
                    // TODO: Add your alert here for successful save
                    
                } else if let error = error {
                    print("Error saving image: \(error.localizedDescription)")
                    
                    provideFeedback(.error)
                }
            }
        }
    }
}

func provideFeedback(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType = .success) {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(feedbackType)
}

// MARK: View Builders

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
    let brick = PBMaterial(
        name: "Brick",
        baseColor: (UIImage(named: "Brick")?.pngData())!,
        normalMap: UIImage(named: "Brick_Normal")?.pngData(),
        roughnessMap: UIImage(named: "Brick_Roughness")?.pngData(),
        displacementMap: UIImage(named: "Brick_Displacement")?.pngData()
    )
    
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

