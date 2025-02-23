/*
 DataModel.swift
 MatCap

 Created by Treata Norouzi on 2/15/25.
 
 Abstract:
 A Data-Model utilizng MLPackages to output required PBR materials
*/

import CoreImage
import SwiftUI
import CoreML
import os

@Observable
class DataModel {
    /// The normal-map model
    @ObservationIgnored
    private var normalGenerator: NormalMapGenerator_CX_Lite_200000_G?
    /// The Roughness/Displacement-map  model
    @ObservationIgnored
    private var roughnessGenerator: FrankenMapGenerator_CX_Lite_215000_G?
    @ObservationIgnored
    private let context = CIContext()

    /// A pixel buffer used as input to the model.
//    let inputPixelBuffer: CVPixelBuffer

    // pub
    /// The last image captured from the camera...
//    var lastImage = OSAllocatedUnfairLock<CIImage?>(uncheckedState: nil)

    
    // pub
    /// The resulting normal texture
    private(set) var normalCGImage: CGImage?
    /// The resulting roughness texture
    private(set) var roughnessCGImage: CGImage?
    /// The resulting roughness texture - `Processed`
    private(set) var displacementCGImage: CGImage?
    
    // delete
    private(set) var compositeCGImage: CGImage?
    
    // Create a reusable buffer to avoid allocating memory for every model invocation
//    @ObservationIgnored private var buffer: CVPixelBuffer!
    
    init() {
        Task.detached(priority: .userInitiated) {
            try? self.loadModels()
        }
    }

    func loadModels() throws {
        print("DataModel(); Loading models...")

        let clock = ContinuousClock()
        let start = clock.now

        normalGenerator = try NormalMapGenerator_CX_Lite_200000_G()

        let nDuration = clock.now - start
        print("Normal Map Generator Model loaded (took \(nDuration.formatted(.units(allowed: [.seconds, .milliseconds]))))")
        
        roughnessGenerator = try FrankenMapGenerator_CX_Lite_215000_G()
        
//        let fDuration = clock.now - nDuration
//        print("roughness Map Generator Model loaded (took \(fDuration.formatted(.units(allowed: [.seconds, .milliseconds]))))")
    }
    
    // TODO: Improve concurrency
    func process(image: UIImage?, inputSize: Int = 384, aspectRatio: Int = 1, orientation: UIImage.Orientation) async throws {
        print("DataModel(); Process")
        guard var image = image else { print("Nil input; nothing to process..."); return }
        guard let normalGenerator else {
            print("Sth wrong with normal model: \(String(describing: normalGenerator))")
            return
        }
        guard let roughnessGenerator else {
            print("Sth wrong with roughness model: \(String(describing: roughnessGenerator))")
            return
        }
        // Free from old images
        self.free()
        

        // Not Necessary
        if false {
            let targetSize = CGSize(width: 384, height: 384)
            if image.size != targetSize {
                image.prepareThumbnail(of: targetSize, completionHandler: { newValue in
                    if let newValue = newValue {
                        image = newValue
                    } else {
                        print("Resizing was Unsuccessful!")
                    }
                    print("Resized image to \(targetSize); imageSize: \(image.size)") })
                print("input Image size was: \(image.size)")
            }
        }

    
        // Large images can take a while to process
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)
//        let aspectRatio: Float = Float(imageWidth / imageHeight) // Returns 0 ...
        let targetWidth = min(imageWidth, inputSize)
        let targetHeight = min(imageHeight, inputSize)
//        print("Input size: \(targetWidth), \(targetHeight)")
        
        guard let pixelBuffer = image.buffer(width: targetWidth, height: targetHeight, orientation: orientation) else {
            print("Faild to obtain image buffer"); return
        }
        
        let normalResult = try normalGenerator.prediction(imageTexture: pixelBuffer /*inputPixelBuffer*/)
        print("Raw normal output's featureNames:\(normalResult.featureNames)\n`CVPixelBuffer`: \(normalResult.normalMap)")
//        inspectBuffer(normalResult.normalMap)
        
        if let cgNormalOutput = CGImage.create(pixelBuffer: normalResult.normalMap) {
            Task.detached(priority: .userInitiated) { @MainActor in
                self.normalCGImage = cgNormalOutput
//                self.normalCGImage = pixelMultiplication(by: 1, for: cgNormalOutput)
            }
        }
        
//        if let correctedNormalBuffer = convertBGRAtoBGR(pixelBuffer: normalResult.normalMap),
//           let cgNormalOutput = CGImage.create(pixelBuffer: correctedNormalBuffer) {
//            Task { @MainActor in
//                self.normalCGImage = cgNormalOutput
//            }
//        }

        
//        if let pixelBuffer = normalResult.normalMap.pixelBuffer {
//            Task { @MainActor in
//                self.normalCGImage =  CGImage.create(pixelBuffer: pixelBuffer)
//            }
//        } else {
////            self.normalCGImage = normalResult.normalMap.postProcessImage(size: 256)
            
//            self.normalCGImage = normalResult.normalMap.cgImage(min: 0, max: 128, channel: nil, axes: (1, 2, 3))
//            
//            let mlArrayShape = normalResult.normalMap.shape
//            print("""
//                array: \(normalResult.normalMap)
//                \(normalResult.normalMapShapedArray)
//                shape of the MLMultiArray: \(mlArrayShape)
//                count: \(mlArrayShape.count)
//                first: \(mlArrayShape[0])
//                second: \(mlArrayShape[1])
//                third: \(mlArrayShape[2])
//                forth: \(mlArrayShape[3])
//                """)
//            print("\(normalResult.normalMap) did not have pixel buffer\n\n")
//        }
        
        
        
        // !!!: Bug: Output PixelBuffer not correctly handled in CGImage; but work fine in XC GUI
        let roughnessResult = try roughnessGenerator.prediction(imageTexture: pixelBuffer)
        print("Raw roughness output's featureNames:\(roughnessResult.featureNames)\n`CVPixelBuffer`: \(roughnessResult.roughnessMap)")
//        inspectBuffer(roughnessResult.roughnessMap)
        
        if let cgRoughness = CGImage.createCGImage(from: roughnessResult.roughnessMap) {
            Task.detached(priority: .userInitiated) { @MainActor in
//                self.compositeCGImage = cgRoughness
                // inverted only fore better results
                self.roughnessCGImage = channelToGrayscale(cgImage: cgRoughness, channel: .blue, invertBlue: true, context: self.context) // Should be green
                //
                self.displacementCGImage = channelToGrayscale(cgImage: cgRoughness, channel: .green, context: self.context) // should be blue
            }
            
//            let (roughnessCGImage, displacementCGImage) = extractGrayscaleImages(from: roughnessResult.roughnessMap)
//            Task { @MainActor in
//                self.roughnessCGImage = roughnessCGImage
//                self.displacementCGImage = displacementCGImage
//            }
        }

//        if let correctedRoughnessBuffer = convertBGRAtoBGR(pixelBuffer: roughnessResult.roughnessMap),
//           let cgRoughnessOutput = CGImage.create(pixelBuffer: correctedRoughnessBuffer) {
//            Task { @MainActor in
//                //
//                self.roughnessCGImage = channelToGrayscale(cgImage: cgRoughnessOutput, channel: .blue)
//                // Currently Obsolete...
//                self.displacementCGImage = channelToGrayscale(cgImage: cgRoughnessOutput, channel: .green)
//            }
//        }
    }
    
    // MARK: Outdated
    /*
    /// Outdated
    private func predictNormal(image: UIImage?) async throws {
        print("DataModel(); predictNormal")
        guard let image = image else { print("Nil input; nothing to process..."); return }
        guard let normalGenerator else {
            print("Sth wrong with normal model: \(String(describing: normalGenerator))")
            return
        }
        
        if image.size != targetSize {
            image.prepareThumbnail(of: targetSize, completionHandler: { _ in print("Resized image to \(targetSize); image size: \(image.size)") })
            print("input Image size: \(image.size)")
        }
        // Ensure this is right!
        let pixelBuffer = image.buffer()!

        // TODO: Convert to BGR
//        context.render(inputImage, to: inputPixelBuffer)


        let result = try normalGenerator.prediction(imageTexture: pixelBuffer /*inputPixelBuffer*/)
        print("Raw output's featureNames:\(result.featureNames)\n`CVPixelBuffer`: \(result.normalMap)")
        
//        let outputImage = CIImage(cvPixelBuffer: mulImage(with: result.normalMap) ?? result.normalMap)

        Task { @MainActor in
            // TODO: - convert BGR to RGB before creating CGImage -
            self.normalCGImage =  CGImage.create(pixelBuffer: result.normalMap)
        }
        
        print("""
                --------------------------------
                normalMap pixel type: \(CVPixelBufferGetPixelFormatType(result.normalMap).magnitude)
                kCVPixelFormatType_128RGBAFloat: \(kCVPixelFormatType_128RGBAFloat.description)
                kCVPixelFormatType_32BGRA: \(kCVPixelFormatType_32BGRA)
                kCVPixelFormatType_32RGBA: \(kCVPixelFormatType_32RGBA)
            """)
    }
    
    /// Outdated
    private func predictRoughness(image: UIImage?) async throws {
        print("DataModel(); predictRoughness")
        guard let image = image else { print("Nil input; nothing to process..."); return }
        guard let roughnessGenerator else {
            print("Sth wrong with roughness model: \(String(describing: roughnessGenerator))")
            return
        }
        
        if image.size != targetSize {
            image.prepareThumbnail(of: targetSize, completionHandler: { _ in print("Resized image to \(targetSize)") })
        }
        // Ensure this is right!
        let pixelBuffer = image.buffer()!
        print("Raw input's attachments:\(pixelBuffer.attachments)\n`CVPixelBuffer`: \(pixelBuffer)")
        
//        let originalSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
//        let inputImage = CIImage(cvPixelBuffer: pixelBuffer).resized(to: targetSize)
        
        let result = try roughnessGenerator.prediction(imageTexture: pixelBuffer /*inputPixelBuffer*/)
        print("Raw output's featureNames:\(result.featureNames)\n`CVPixelBuffer`: \(result.roughnessMap)")
        
        Task { @MainActor in
            if let result = CGImage.create(pixelBuffer: result.roughnessMap) {
                //
                self.roughnessCGImage = channelToGrayscale(cgImage: result, channel: .red)
                // Currently Obsolete...
                self.displacementCGImage = channelToGrayscale(cgImage: result, channel: .green)
            }
        }
    }
     */
     
    func free() {
        self.normalCGImage = nil
        self.roughnessCGImage = nil
        self.displacementCGImage = nil
    }
}

// MARK: - Tests

private struct TestsForDataModel: View {
    var inputImage: UIImage
    
    @Bindable private var model = DataModel()
    
    @State private var normalImage: CGImage?
    @State private var roughnessImage: CGImage?
    @State private var compositeImage: CGImage?
    @State private var displacementImage: CGImage?
    
    var body: some View {
        ScrollView(.vertical) {
        VStack {
            Group {
                Image(.brick).resizable()
                
                //                image?.resizable()
                
                if let normalImage = normalImage/*, let finalImage = pixelMultiplication(by: 1, for: normalImage)*/ {
                    Image(normalImage, scale: 1, orientation: .up, label: Text(""))
                        .resizable()
                    //                            .toBGR()
                }
                
                if let roughnessImage = roughnessImage {
                    Image(roughnessImage, scale: 1, orientation: .up, label: Text("1"))
                        .resizable()
                }
                
                //                if let cgImage = self.cgImage {
                //                    Image(cgImage, scale: 1, orientation: .up, label: Text("")).resizable()
                //                        .multiply(value: 255)
                //                        .toBGR()
                //                }
                
                
                if let compositeImage = compositeImage {
                    Image(compositeImage, scale: 1, orientation: .up, label: Text("2"))
                        .resizable()
                    //                            .toBGR()
                }
                
                if let displacementImage = displacementImage {
                    Image(displacementImage, scale: 1, orientation: .up, label: Text("2"))
                        .resizable()
                    //                            .toBGR()
                }
            }
            .frame(width: 196, height: 196)
        }
        .onTapGesture {
            print("tapped")
            Task {
                try? await model.process(image: .brick, orientation: .up)
                //                try! await model.predictNormal(image: inputImage)
                //                self.image = model.normalOutput
                self.normalImage = model.normalCGImage
                
                //                try! await model.predictRoughness(image: inputImage)
                
                // Green channel represents the Roughness in GrayScale
                self.roughnessImage = model.roughnessCGImage
                self.compositeImage = model.compositeCGImage
                self.displacementImage = model.displacementCGImage
            }
        }
        
    }
    }
}

#Preview("Tests For DataModel") {
    TestsForDataModel(inputImage: .brick)
}

// MARK: - Extension

import CoreImage

// Duplicate
private func convertBGRAtoBGR(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    
    // Create a filter to reorder channels and drop alpha
    guard let filter = CIFilter(name: "CIColorMatrix") else { return nil }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    
    // BGRA -> BGR: B stays B, G stays G, R becomes R from BGR order, A ignored
    filter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector") // R -> B (from BGR intent)
    filter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector") // G -> G
    filter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector") // B -> R
    filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector") // A -> 0 (drop alpha)
    
    guard let outputImage = filter.outputImage else { return nil }
    
    // Create a new CVPixelBuffer (3-channel BGR or keep BGRA format)
    var newPixelBuffer: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault,
                        CVPixelBufferGetWidth(pixelBuffer),
                        CVPixelBufferGetHeight(pixelBuffer),
                        kCVPixelFormatType_32BGRA, // Or use kCVPixelFormatType_24RGB for 3-channel
                        nil,
                        &newPixelBuffer)
    
    let context = CIContext()
    if let newBuffer = newPixelBuffer {
        context.render(outputImage, to: newBuffer)
        return newBuffer
    }
    return nil
}

// MARK: --

import CoreImage
import CoreVideo
import CoreGraphics

extension CGImage {
    // Convert CIImage to CGImage in GenericGrayGamma2_2 color space
    static func createGrayscale(from ciImage: CIImage) -> CGImage? {
        let context = CIContext()
        let colorSpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)
        return context.createCGImage(ciImage, from: ciImage.extent, format: .L8, colorSpace: colorSpace)
    }
}

func extractGrayscaleImages(from pixelBuffer: CVPixelBuffer) -> (roughness: CGImage?, displacement: CGImage?) {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    
    // Filter to extract Green channel (roughness)
    guard let redFilter = CIFilter(name: "CIColorMatrix") else { return (nil, nil) }
    redFilter.setValue(ciImage, forKey: kCIInputImageKey)
    redFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector") // R = 1
    redFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector") // G = 0
    redFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector") // B = 0
    redFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector") // A = 1
    
    // Filter to extract Red channel (displacement)
    guard let greenFilter = CIFilter(name: "CIColorMatrix") else { return (nil, nil) }
    greenFilter.setValue(ciImage, forKey: kCIInputImageKey)
    greenFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector") // R = 0
    greenFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector") // G = G
    greenFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector") // B = 0
    greenFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector") // A = 1
    
    // Get output images
    guard let redOutput = redFilter.outputImage,
          let greenOutput = greenFilter.outputImage else { return (nil, nil) }
    
    // Convert to CGImage with GenericGrayGamma2_2 color space
    let roughnessImage = CGImage.createGrayscale(from: greenOutput)
    let displacementImage = CGImage.createGrayscale(from: redOutput)
    
    return (roughness: roughnessImage, displacement: displacementImage)
}
