//
//  PhotosPicker.swift
//  MatCap
//
//  Created by Treata Norouzi on 2/15/25.
//


import SwiftUI
import PhotosUI

struct PhotosPickerView<Content: View>: View {
    var label: Content
    
    init(@ViewBuilder label:  @escaping () -> Content) {
        self.label = label()
    }
    
    //MARK: Properties
    //@State private var selectedItem: [PhotosPickerItem] = [PhotosPickerItem]() // use to select multiple images from gallery
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    var body: some View {
        VStack {
                PhotosPicker(
                    selection: $selectedItem,
                   // maxSelectionCount: 2, //set max selection from gallery
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    label
                }
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task { // Incase of multiple selection newValue is of array type
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }
            
            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16).stroke(Color.yellow, lineWidth: 8)
                    )
            }
        }
        .padding()
    }
}

#Preview {
    PhotosPickerView(label: {
        Text("Choose Photos from Gallery")
            .frame(width: 350, height: 50)
            .background(Capsule().stroke(lineWidth: 2))
    })
}
