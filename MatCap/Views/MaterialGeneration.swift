//
//  MaterialGeneration.swift
//  MatCap
//
//  Created by Treata Norouzi on 2/19/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct CreateMaterialView: View {
    @Bindable var dataModel: DataModel
    
    @Environment(\.modelContext) private var modelContext
    @Query private var materials: [PBMaterial]
    
    @State private var name: String = ""
    @State private var previewResults = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            GeometryReader {
                let size = $0.size
                let spacerLength = min(size.width, size.height) / 10
                let third = size.width/3
                
                ScrollView(.vertical) {
                    VStack(alignment: .center) {
                        HStack {
                            Text("Material Name: ")
                            TextField("Type a name...", text: $name)
                        }
                        
                        Spacer(minLength: spacerLength)
                        
                        Text("Base Color Texture: ")
                        if let imageData = selectedImageData {
                            textureView(from: imageData, width: size.width)
                        }
                        HStack(alignment: .center) {
                            Group {
                                camera
                                photosLibrary
                            }
                            .frame(width: third, height: third)
                        }
                        
                        Spacer(minLength: spacerLength)
                        
                        if self.selectedImageData != nil {
                            textureView(from: normalData, width: size.width)
                            
                            Spacer(minLength: spacerLength)
                            
                            textureView(from: roughnessData, width: size.width)
                        }
                        
                        Spacer(minLength: spacerLength * 2)
                        
                        //            HStack {
                        //                ARPreviewContainer()
                        //            }
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Material")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                    })
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    saveMaterial
                }
            })
        }
        .onChange(of: selectedImageData) { oldValue, newValue in
            if let newValue = newValue {
                Task {
                    await processMaterial(name: name, imageData: newValue)
                }
            }
        }
    }
    
    // MARK: Helper Views
    
    var saveMaterial: some View {
        Button(action: {
            if selectedImageData != nil && !name.isEmpty, let data = selectedImageData {
                Task {
                    // !!!: Bogus
                    let newMaterial = await processMaterial(name: self.name, imageData: data)
                    add(material: newMaterial)
                    
                    dismiss()
                }
            }
        }, label: {
            Text("Save Material")
                .font(.headline)
//                .padding()
////                .frame(width: 150, height: 50)
//                .background(Capsule().stroke(lineWidth: 2))
        })
        .disabled(self.selectedImageData == nil || self.name.isEmpty)
    }
    
    @State private var isCameraUp = false
    
    var camera: some View {
        Button(action: {
            self.isCameraUp = true
        }, label: {
            VStack(alignment: .center) {
//                Image(systemName: "camera")
                CameraIcon()
                Text("Camera")
            }
            .padding()
        })
        .fullScreenCover(isPresented: $isCameraUp, content: {
            Camera(
                handlePickedImage: { image in handleShotPhoto(image) },
                isPresented: $isCameraUp
            )
            .ignoresSafeArea()
//            CamView(image: $camVM.currentFrame)
        })
    }

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    @MainActor
    func handleShotPhoto(_ image: UIImage?) {
        if let data = image?.pngData() {
            selectedImageData = data
            isCameraUp = false
        }
    }

    // TODO: AutoCrop to Square images
    var photosLibrary: some View {
        PhotosPicker(
            selection: $selectedItem,
           // maxSelectionCount: 2, //set max selection from gallery
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(alignment: .center) {
//                Image(systemName: "photo")
                EnhacedPhotosIcon()
                Text("Photos")
            }
            .padding()
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task { // Incase of multiple selection newValue is of array type
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    let image = UIImage(data: data)
                    if image!.size.width != image?.size.height {
                        // TODO: Make sure it's right
                        self.selectedImageData = image?.squared?.pngData()
                    } else {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    @State private var normalData: Data? = nil
    @State private var roughnessData: Data? = nil
//    @State private var newMaterial: PBMaterial
    private func processMaterial(name: String, imageData: Data) async -> PBMaterial {
        let uiImage = UIImage(data: imageData)
        Task {
            // TODO: Handle
            try? await dataModel.process(image: uiImage)
        }
        
        let newMaterial = PBMaterial(name: name, baseColor: imageData)
        
        // TODO: Summarize
        if let normalCGImage = dataModel.normalCGImage {
            normalData = normalCGImage.png
            self.normalData = normalData
            newMaterial.normalMap = normalData
            
            if let roughnessCGImage = dataModel.roughnessCGImage {
                roughnessData = roughnessCGImage.png
                self.roughnessData = roughnessData
                newMaterial.roughnessMap = roughnessData
            }
        }

        return newMaterial
    }
    
    private func add(material: PBMaterial) {
        withAnimation {
            self.modelContext.insert(material)
        }
    }
}

#Preview("Create Material") { CreateMaterialView(dataModel: DataModel()) }

// MARK: - Extensions

extension UIImage {
    var squared: UIImage? {
        guard let cgImage = cgImage else { return nil }
        let length = min(cgImage.width, cgImage.height)
        let x = cgImage.width / 2 - length / 2
        let y = cgImage.height / 2 - length / 2
        let cropRect = CGRect(x: x, y: y, width: length, height: length)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }
}

struct ContentView: View {
    let image: UIImage
    var body: some View {
        Image(uiImage: image.squared ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

extension CGImage {
    var png: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
