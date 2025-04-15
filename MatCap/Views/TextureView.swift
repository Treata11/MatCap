/*
 TextureView.swift
 MatCap

 Created by Treata Norouzi on 2/6/25.
*/

import AVFoundation
import SwiftUI

struct TextureView: View {
    @Binding var image: Image?

    var body: some View {
        if let image = image {
            image.resizable().aspectRatio(contentMode: .fill)
        } else {
            Text(":( No Image").font(.largeTitle)
        }
    }
}

#Preview {
    TextureView(image: .constant(Image(.brick)))
}

