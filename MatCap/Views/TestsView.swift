////
////  TestsView.swift
////  MatCap
////
////  Created by Treata Norouzi on 2/6/25.
////
//
//import SwiftUI
//
//public extension View {
//    func multiply(value: Float) -> some View {
//        self.colorEffect(ShaderLibrary.default.multiply(.float(value)))
//    }
//    
//    func toBGR() -> some View {
//        self.colorEffect(ShaderLibrary.default.toBGR())
//    }
//}
//
//struct TestsView: View {
//    @StateObject private var model = ΤestDataModel()
//    
//    @State private var image: Image?
//    @State private var cgImage: CGImage?
//    
//    var body: some View {
//        VStack {
//            Group {
//                Image(.example).resizable()
//                
////                image?.resizable()
//                
//                if let cgImage = cgImage {
//                    Image(doStuff(with: cgImage) ?? cgImage, scale: 1, orientation: .up, label: Text("CGImage Output")).resizable()
////                        .toBGR()
//                }
//                
//                if let img = self.image {
//                    img.resizable()
//                        .multiply(value: 255)
//                        .toBGR()
//                }
//            }
//            .frame(width: 256, height: 256)
//            
//            Button("Copy Image to Clipboard") {
//                copyImageToClipboard(uiImage: UIImage(ciImage: model.rawModelResults!))
//            }
//            .padding()
//        }
//        .onTapGesture {
//            print("tapped")
//            Task {
//                try! await model.predict()
//                self.image = model.output
//                self.cgImage = model.cgOutputImage
//            }
//            
//            print(self.image)
//        }
//    }
//}
//
//// MARK: - Tests Model
//
//import CoreImage
//import CoreML
////import SwiftUI
//import os
//
////@Observable
//fileprivate final class ΤestDataModel: ObservableObject {
//    let context = CIContext()
//
//    /// The normal-map model.
//    var model: NormalMapGenerator_CX_Lite_200000_G?
//
//    /// A pixel buffer used as input to the model.
//    let inputPixelBuffer: CVPixelBuffer
//
//    /// The last image captured from the camera.
//    var lastImage = OSAllocatedUnfairLock<CIImage?>(uncheckedState: nil)
//
//    /// The resulting texture
//    @Published var output: Image?
//    @Published var cgOutputImage: CGImage?
//    
//    
//    @Published var rawModelResults: CIImage?
//    
//    // Create a reusable buffer to avoid allocating memory for every model invocation
//    private var buffer: CVPixelBuffer!
//    
//    init() {
//
//        let status = CVPixelBufferCreate(
//            kCFAllocatorDefault,
//            Int(256),
//            Int(256),
//            kCVPixelFormatType_32ARGB, // should be BGR
//            nil,
//            &buffer
//        )
//        guard status == kCVReturnSuccess else {
//            fatalError("Failed to create pixel buffer")
//        }
//        inputPixelBuffer = buffer
//
//        // Decouple running the model from the camera feed since the model will run slower
//        Task.detached(priority: .userInitiated) {
//            await self.runModel()
////            try await self.predict()
//        }
//    }
//
//    func runModel() async {
//        try! loadModel()
//
////        let clock = ContinuousClock()
////        var durations = [ContinuousClock.Duration]()
//
//        print("Going for performInference() now")
//        
////        while !Task.isCancelled {
////            let image = lastImage.withLock({ $0 })
////            if let pixelBuffer = image?.pixelBuffer {
////                let duration = await clock.measure {
////                    try? await performInference(pixelBuffer)
////                }
////                durations.append(duration)
////            } else {
////                print("image/lastImage was nil")
////            }
////
////            let measureInterval = 100
////            if durations.count == measureInterval {
////                let total = durations.reduce(Duration(secondsComponent: 0, attosecondsComponent: 0), +)
////                let average = total / measureInterval
////                print("Average model runtime: \(average.formatted(.units(allowed: [.milliseconds])))")
////                durations.removeAll(keepingCapacity: true)
////            }
////
////            // Slow down inference to prevent freezing the UI
////            try? await Task.sleep(for: .milliseconds(10_000_000))
////        }
//    }
//
//    func loadModel() throws {
//        print("Loading model...")
//
//        let clock = ContinuousClock()
//        let start = clock.now
//
//        model = try NormalMapGenerator_CX_Lite_200000_G()
//
//        let duration = clock.now - start
//        print("Model loaded (took \(duration.formatted(.units(allowed: [.seconds, .milliseconds]))))")
//    }
//    
//    
//
////    func performInference(_ pixelBuffer: CVPixelBuffer) async throws {
////        print("performInference") // mine
////        guard let model else {
////            print("Sth wrong with model: \(String(describing: model))")
////            return
////        }
////
////        let originalSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
////        let inputImage = CIImage(cvPixelBuffer: pixelBuffer).resized(to: targetSize)
//////        let inputImage = CIImage(image: UIImage(named: "example")!)!.resized(to: targetSize) // mine
////        context.render(inputImage, to: inputPixelBuffer)
////        let result = try model.prediction(Image_Texture: inputPixelBuffer) // TODO: Rename Image_Texture
////        let outputImage = CIImage(cvPixelBuffer: result.Normal_Map) // TODO: Rename Normal_Map
////
////        Task { @MainActor in
////            output = outputImage
////                .resized(to: originalSize)
////                .image
////            print("Output is: \n\(String(describing: output))\n\n")
////        }
////    }
//    
//    /// Feb 7th
//    public func predict(image: UIImage? = UIImage(named: "example")) async throws {
//        print("predict")
//        guard let model else {
//            print("Sth wrong with model: \(String(describing: model))")
//            return
//        }
//        let samplePixels: [(Int, Int)] = [(0, 0), (1, 1), (63, 63), (64, 64), (127, 127), (128, 128), (255, 255)]
//        
//        // Ensure this is right!
//        let pixelBuffer = image?.buffer(width: image?.size.width, height: image?.size.height)!
//        print("Raw input's attachments:\(pixelBuffer!.attachments)\n`CVPixelBuffer`: \(pixelBuffer!)")
//
//        let originalSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer!), height: CVPixelBufferGetHeight(pixelBuffer!))
//        let inputImage = CIImage(cvPixelBuffer: pixelBuffer!)/*.resized(to: targetSize)*/
//        // !!!: should you?
////        context.render(inputImage, to: inputPixelBuffer)
//        
//        print("\n\nInput Images:")
////        _ = inputImage.collectRGBValues(of: samplePixels)
////        printPixelBufferRGBValues(pixelBuffer: pixelBuffer!)
//        // TODO: Adjust the input image
//        
//        let result = try model.prediction(imageTexture: pixelBuffer! /*inputPixelBuffer*/)
//        print("Raw output's featureNames:\(result.featureNames)\n`CVPixelBuffer`: \(result.normalMap)")
//        
////        let outputImage = CIImage(cvPixelBuffer: mulImage(with: result.normalMap) ?? result.normalMap)
//        
//        print("\n\nOutput Images (not adjusted)")
////        printPixelBufferRGBValues(pixelBuffer: result.normalMap)
//        // IMP: all pixels (overkill)
////        var allPixels: [(Int, Int)] = []
////        for x in 0..<Int(outputImage.extent.width) {
////            for y in 0..<Int(outputImage.extent.height) {
////                allPixels.append((x, y))
////            }
////        }
////        _ = outputImage.collectRGBValues(of: allPixels)
////        _ = outputImage.collectRGBValues(of: samplePixels)
//
//        Task { @MainActor in
////            self.rawModelResults = outputImage
////            self.output = outputImage
////                .resized(to: originalSize)
////                .image
//            
//            // TODO: - convert BGR to RGB before creating CGImage -
//    //        self.cgOutputImage = CGImage.create(pixelBuffer: result.normalMap)
////            self.cgOutputImage = processCoreMLOutput(pixelBuffer: result.normalMap)
////            self.cgOutputImage = CGImage.create(pixelBuffer: result.normalMap)
//            
////            print("""
////                    --------------------------------
////                    \(CVPixelBufferGetPixelFormatType(result.normalMap).description)\n
////                    kCVPixelFormatType_128RGBAFloat: \(kCVPixelFormatType_128RGBAFloat.description)\n
////                    kCVPixelFormatType_32BGRA: \(kCVPixelFormatType_32BGRA)
////                """)
//            
////            print("IMP:::CVPixelBufferGetBaseAddress \n\(String(describing: CVPixelBufferGetBaseAddress(result.normalMap)))")
////            self.output = Image(mulImage3(with: result.normalMap)!, scale: 1, label: Text("Hi"))
//        }
//    }
//    
//    ///
//    private func adjust(ciImage: CIImage) -> CIImage {
//        // Create a CIFilter to adjust brightness
//        let brightnessFilter = CIFilter(name: "CIColorMatrix")!
//        
//        // Set the input image
//        brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
//        
//        // Wrong
////        let rScale = 0.081707
////        let rBias = 0.787871
////        
////        let gBias = 0.301230
////        let gScale = 1.9704850097
//        
//        // Define the matrix to multiply RGB values by 255
//        let multiplier: CGFloat = 255
//        brightnessFilter.setValue(CIVector(x: multiplier, y: 0, z: 0, w: 0), forKey: "inputRVector")
//        brightnessFilter.setValue(CIVector(x: 0, y: multiplier /** gScale + gBias*/, z: 0, w: 0), forKey: "inputGVector")
//        brightnessFilter.setValue(CIVector(x: 0, y: 0, z: multiplier, w: 0), forKey: "inputBVector")
//        brightnessFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
//        
//        // Get the output image from the filter
//        if let adjustedImage = brightnessFilter.outputImage {
//            // Now 'adjustedImage' contains your modified CIImage with RGB values multiplied by 255
//            // You can continue processing or display this image as needed.
//            
//            return adjustedImage
//        }
//        
//        return ciImage
//    }
//    
//    private func increaseBrightness(of ciImage: CIImage) -> CIImage {
//        // Create a CIFilter to adjust brightness
//        let brightnessFilter = CIFilter(name: "CIColorMatrix")!
//        
//        // Set the input image
//        brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
//
//        let gBias = 0.301230
//        // Define the matrix for adding a value to RGB channels
//        brightnessFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
//        brightnessFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
//        brightnessFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
//        brightnessFilter.setValue(CIVector(x: gBias, y: gBias, z: gBias, w: 0), forKey: "inputAVector")
//
//        // Get the output image from the filter
//        if let adjustedImage = brightnessFilter.outputImage {
//            return adjustedImage
//        }
//        
//        return ciImage
//    }
//}
//
//// MARK: - RGB Collection
//
//extension CIImage {
//    func collectRGBValues(of pixels: [(Int, Int)], saveToFile: Bool = false, filePath: String? = nil) -> [String: (Float, Float, Float)] {
//        guard let cgImage = CIContext().createCGImage(self, from: extent) else {
//            print("Error: Could not create CGImage from CIImage.")
//            return [:]
//        }
//
//        var pixelData: [String: (Float, Float, Float)] = [:]
//
//        for pixel in pixels {
//            let x = pixel.0
//            let y = pixel.1
//
//            guard x >= 0 && x < Int(extent.width) && y >= 0 && y < Int(extent.height) else {
//                print("Warning: Pixel (\(x), \(y)) is outside the image bounds.")
//                continue
//            }
//
//            let color = getPixelColor(cgImage: cgImage, x: x, y: y)
//
//            pixelData["(\(x), \(y))"] = (Float(color.red), Float(color.green), Float(color.blue))
//        }
//
//        if saveToFile {
//            let fileURL = filePath != nil ? URL(fileURLWithPath: filePath!) : FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("rgb_values.txt")
//
//            var fileContent = ""
//            for (pixel, rgb) in pixelData {
//                fileContent += "\(pixel): R=\(rgb.0), G=\(rgb.1), B=\(rgb.2)\n"
//            }
//
//            do {
//                try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
//                print("RGB values saved to file: \(fileURL)")
//            } catch {
//                print("Error: Could not write to file: \(error)")
//            }
//        } else {
//            // Print to console (less desirable for large images)
//            for (pixel, rgb) in pixelData {
//                print("\(pixel): R=\(rgb.0), G=\(rgb.1), B=\(rgb.2)")
//            }
//        }
//
//        return pixelData
//    }
//
//
//    // FIXME: UInt8 Precision which is low
//    // Returns Int ...
//    private func getPixelColor(cgImage: CGImage, x: Int, y: Int) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
//        let pixelData = cgImage.dataProvider!.data
//        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData!)
//
//        let bytesPerPixel = cgImage.bitsPerPixel / 8
//        let pixelInfo: Int = ((Int(cgImage.width) * y) + x) * bytesPerPixel
//
////        let red = CGFloat(data[pixelInfo]) / CGFloat(255.0)
////        let green = CGFloat(data[pixelInfo + 1]) / CGFloat(255.0)
////        let blue = CGFloat(data[pixelInfo + 2]) / CGFloat(255.0)
//
//        return (CGFloat(data[pixelInfo]) , CGFloat(data[pixelInfo + 1]), CGFloat(data[pixelInfo + 2]))
//    }
//}
//
//// MARK: - Feb 9th
//
//import Accelerate
//
//func printPixelBufferRGBValues(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
//    // Lock the base address of the pixel buffer. This gives you direct memory access.
//    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
//    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) } // Ensure it's unlocked
//
//    // Get basic information about the buffer.
//    let width = CVPixelBufferGetWidth(pixelBuffer)
//    let height = CVPixelBufferGetHeight(pixelBuffer)
//    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//
//    // Check for nil baseAddress
//    guard let baseAddressUnsafeMutablePointer = baseAddress else {
//        print("Error: Could not get base address of pixel buffer.")
//        return nil
//    }
//
//    // Determine pixel format.  This is crucial for correct access.  Assuming BGRA.
//    let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
//    guard pixelFormatType == kCVPixelFormatType_32BGRA else {
//        print("Error: Pixel format is not BGRA. Expected kCVPixelFormatType_32BGRA (\(kCVPixelFormatType_32BGRA)), but got \(pixelFormatType).")
//        return nil
//    }
//
//    // Access the pixel data. We treat it as an array of Float32 (bytes). Each pixel is BGRA, hence 4 bytes per pixel.
//    let buffer = baseAddressUnsafeMutablePointer.assumingMemoryBound(to: Float32.self)
//
//    // Iterate through a subset of pixels (e.g., every 64th pixel) to avoid overwhelming the console.  Adjust the stride as needed.
//    let stride = 64 // Print every 64th pixel. Reduce for more. Increase for less.
//
//    print("Printing RGB values for a subset of pixels (stride=\(stride))...")
//    for y in stride..<height where y % stride == 0 {
//        for x in stride..<width where x % stride == 0 {
//            // Calculate the index into the buffer for this pixel.
//            let pixelIndex = (x * 4) + (y * bytesPerRow)
//
//            // Extract the BGRA values.  Order is *important*.  It's BGRA, *not* RGBA.
//            let b = Float(buffer[pixelIndex + 0]) // Blue
//            let g = Float(buffer[pixelIndex + 1]) // Green
//            let r = Float(buffer[pixelIndex + 2]) // Red
//            let a = Float(buffer[pixelIndex + 3]) // Alpha
//
//            // Print the RGB values (and Alpha) for this pixel.
//            print("Pixel (\(x), \(y)): R: \(String(format: "%.6f", r)), G: \(String(format: "%.6f", g)), B: \(String(format: "%.6f", b)), A: \(String(format: "%.6f", a))")
//        }
//    }
//
//    print("Finished printing RGB values.")
//    
//
//    
//    
////    // Calculate the total number of pixels
////        let totalPixels = width * height
////        
////        // Create an array to hold the output values
////        var outputBuffer = [Float32](repeating: 0, count: totalPixels * 4) // 4 channels (BGRA)
////
////        // Use vDSP to multiply the RGBA values by 255
////        var multiplier: Float32 = 255.0
////        vDSP_vsmul(buffer, 1, &multiplier, &outputBuffer, 1, vDSP_Length(totalPixels * 4))
////
////        // Create a new pixel buffer to hold the modified values
////        var newPixelBuffer: CVPixelBuffer?
////        let status = CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &newPixelBuffer)
////
////        guard status == noErr, let newBuffer = newPixelBuffer else {
////            print("Error: Could not create new pixel buffer.")
////            return nil
////        }
////
////        // Lock the base address of the new pixel buffer for writing
////        CVPixelBufferLockBaseAddress(newBuffer, .readOnly)
////        defer { CVPixelBufferUnlockBaseAddress(newBuffer, .readOnly) }
////
////        // Get the base address of the new pixel buffer
////        let newBaseAddress = CVPixelBufferGetBaseAddress(newBuffer)
////        
////        // Check for nil baseAddress
////        guard let newBaseAddressUnsafeMutablePointer = newBaseAddress else {
////            print("Error: Could not get base address of new pixel buffer.")
////            return nil
////        }
////
////        // Copy the output buffer to the new pixel buffer
////    memcpy(newBaseAddressUnsafeMutablePointer, outputBuffer, outputBuffer.count * MemoryLayout<UInt8>.size)
////
////        return newBuffer
//
//    
//
//    
////    let numberOfPixels = width * height
////       let numberOfFloats = numberOfPixels * 4 // BGRA, so 4 floats per pixel.
////
////       // Allocate a new buffer for the result. This is crucial for avoiding modifying the original buffer.
////       var multipliedBuffer = [Float32](repeating: 0.0, count: numberOfFloats)
////
////       // Multiply by 255 using vDSP.
////       var scale: Float32 = 255.0
////       vDSP_vsmul(buffer, 1, &scale, &multipliedBuffer, 1, vDSP_Length(numberOfFloats))
////
////       // Create a new pixel buffer for the output.
////       var outputPixelBuffer: CVPixelBuffer? = nil
////       let attrs = [
////           kCVPixelBufferPixelFormatTypeKey as String: pixelFormatType,
////           kCVPixelBufferWidthKey as String: width,
////           kCVPixelBufferHeightKey as String: height,
////           kCVPixelBufferIOSurfacePropertiesKey as String: [:]
////       ] as CFDictionary
////
////       let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormatType, attrs, &outputPixelBuffer)
////
////       guard status == kCVReturnSuccess, let outputBuffer = outputPixelBuffer else {
////           print("Error: Could not create output pixel buffer. Status: \(status)")
////           return nil
////       }
////
////       // Lock the base address of the output buffer.
////       CVPixelBufferLockBaseAddress(outputBuffer, [])
////       defer { CVPixelBufferUnlockBaseAddress(outputBuffer, []) }
////
////       // Get the base address of the output buffer.
////       guard let outputBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer) else {
////           print("Error: Could not get base address of output pixel buffer.")
////           return nil
////       }
////
////       // Copy the multiplied data into the output buffer.
////       let outputBufferPointer = outputBaseAddress.assumingMemoryBound(to: Float32.self)
////    memcpy(outputBufferPointer, multipliedBuffer, numberOfFloats * MemoryLayout<UInt8>.size)
//
////    vImageMatrixMultiply_ARGBFFFF(<#T##src: UnsafePointer<vImage_Buffer>##UnsafePointer<vImage_Buffer>#>, <#T##dest: UnsafePointer<vImage_Buffer>##UnsafePointer<vImage_Buffer>#>, <#T##matrix: UnsafePointer<Float>##UnsafePointer<Float>#>, <#T##pre_bias: UnsafePointer<Float>!##UnsafePointer<Float>!#>, <#T##post_bias: UnsafePointer<Float>!##UnsafePointer<Float>!#>, <#T##flags: vImage_Flags##vImage_Flags#>)
//
//    return pixelBuffer
//}
//
//// MARK: - Feb 10th
//
//import CoreVideo
//import Foundation
//
//// https://stackoverflow.com/questions/52415135/get-pixel-rgb-value-from-cvpixelbuffer-on-swift-4
////func convert(imageBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
////    guard CVPixelBufferGetPixelFormatType(imageBuffer) == kCVPixelFormatType_32BGRA else {
////        print("throw ConversionError.invalidPixelFormat")
////    }
////    guard CVPixelBufferLockBaseAddress(imageBuffer, .readOnly) == kCVReturnSuccess else {
////        print("throw ConversionError.bufferLockError")
////    }
////    defer {
////        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
////    }
////    guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {
////        print("throw ConversionError.invalidImageBuffer")
////    }
////    let width = CVPixelBufferGetWidth(imageBuffer)
////    let height = CVPixelBufferGetHeight(imageBuffer)
////    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
////    //Prepare 32BGRA source buffer
////    var srcBuffer = vImage_Buffer(data: baseAddress,
////                                  height: vImagePixelCount(height),
////                                  width: vImagePixelCount(width),
////                                  rowBytes: bytesPerRow)
////    //Prepare destination RGB data
////    let rgbBytesPerRow = width * 3
////    var rgbData = Data(count: height * rgbBytesPerRow)
////    let rawDestinationPtr = rgbData.withUnsafeMutableBytes{ $0.baseAddress }
////    guard let rawDestinationPtr = rawDestinationPtr else {
////        print("throw ConversionError.bufferLockError")
////    }
////    var destBuffer = vImage_Buffer(data: rawDestinationPtr,
////                                   height: vImagePixelCount(height),
////                                   width: vImagePixelCount(width),
////                                   rowBytes: rgbBytesPerRow)
////    //Apply conversion BGRA -> RGB using Accelerate framework (CPU)
////    let error = vImageConvert_BGRA8888toRGB888(&srcBuffer, &destBuffer, vImage_Flags(kvImageNoFlags))
////    guard error == kvImageNoError else {
////        print("throw ConversionError.BGRA8888toRGB888Conversion")
////    }
////    
////    
////    return Rgb888ImageData(rgbData: rgbData, imageWidth: width, imageHeight: height)
////}
//
//
//
//// Define the multiplication factor
////let factor: Float = 2.0
////
////// Define the divisor to ensure the pixel values remain within the valid range
////let divisor: Float = 1.0
////
////// Define the pre-bias and post-bias values (usually set to 0 for simple multiplication)
////let preBias: [Int16] = [0, 0, 0, 0]
////let postBias: [Int16] = [0, 0, 0, 0]
////
////// Apply the multiplication
////multiply(by: factor, divisor: divisor, preBias: preBias, postBias: postBias, destination: &destinationBuffer)
//
//
//
//
//
//import Accelerate
//import CoreVideo
//import CoreImage
//
//func mulImage(with pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
//    // Lock the base address of the pixel buffer. This gives you direct memory access.
//    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
//    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) } // Ensure it's unlocked
//
//    // Get basic information about the buffer.
//    let width = CVPixelBufferGetWidth(pixelBuffer)
//    let height = CVPixelBufferGetHeight(pixelBuffer)
//    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//
//    // Check for nil baseAddress
//    guard let baseAddressUnsafeMutablePointer = baseAddress else {
//        print("Error: Could not get base address of pixel buffer.")
//        return nil
//    }
//
//    // Determine pixel format.  This is crucial for correct access.  Assuming BGRA.
//    let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
//    guard pixelFormatType == kCVPixelFormatType_32BGRA else {
//        print("Error: Pixel format is not BGRA. Expected kCVPixelFormatType_32BGRA (\(kCVPixelFormatType_32BGRA)), but got \(pixelFormatType).")
//        return nil
//    }
//
//
//    // **********************************************************************************
//    // Using vImageMatrixMultiply_ARGBFFFF
//    // **********************************************************************************
//
//    // 1. Create a vImage_Buffer from the CVPixelBuffer (source).
//
//    var sourceBuffer = vImage_Buffer(data: baseAddressUnsafeMutablePointer,
//                                       height: vImagePixelCount(height),
//                                       width: vImagePixelCount(width),
//                                       rowBytes: bytesPerRow)
//
//    // 2. Create a destination CVPixelBuffer in ARGB format (for vImageMatrixMultiply_ARGBFFFF)
//    var destPixelBuffer: CVPixelBuffer?
//    let destPixelFormatType = kCVPixelFormatType_32ARGB
//
//    let attrs = [
//        kCVPixelBufferPixelFormatTypeKey as String: destPixelFormatType,
//        kCVPixelBufferWidthKey as String: width,
//        kCVPixelBufferHeightKey as String: height,
//    ] as CFDictionary
//
//    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, destPixelFormatType, attrs, &destPixelBuffer)
//
//    guard status == kCVReturnSuccess, let destinationPixelBuffer = destPixelBuffer else {
//        print("Error: Could not create destination pixel buffer.")
//        return nil
//    }
//
//    CVPixelBufferLockBaseAddress(destinationPixelBuffer, [])
//    defer { CVPixelBufferUnlockBaseAddress(destinationPixelBuffer, []) }
//
//    guard let destBaseAddress = CVPixelBufferGetBaseAddress(destinationPixelBuffer) else {
//        print("Error: Could not get base address of destination pixel buffer.")
//        return nil
//    }
//
//    let destBytesPerRow = CVPixelBufferGetBytesPerRow(destinationPixelBuffer)
//
//    var destinationBuffer = vImage_Buffer(data: destBaseAddress,
//                                           height: vImagePixelCount(height),
//                                           width: vImagePixelCount(width),
//                                           rowBytes: destBytesPerRow)
//
//    // Convert from BGRA -> ARGB
//    var permuteMap: [UInt8] = [3, 2, 1, 0] // BGRA -> ARGB
//    vImagePermuteChannels_ARGB8888(&sourceBuffer, &destinationBuffer, &permuteMap, vImage_Flags(kvImageNoFlags))
//
//    return destPixelBuffer
//    
//    
//    
//
//    // 3. Define the multiplication matrix.  We want to multiply R, G, and B by 255.0,
//    //    and leave A unchanged.  Since we are using Float32, we use floating-point numbers.
//    //    The matrix is a 4x4 matrix (RGBA -> RGBA).
//    let scaleFactor: Float = 255.0
//    var matrix: [Float] = [
//        scaleFactor, 0.0,       0.0,       0.0,   // R' = scaleFactor * R
//        0.0,       scaleFactor, 0.0,       0.0,   // G' = scaleFactor * G
//        0.0,       0.0,       scaleFactor, 0.0,   // B' = scaleFactor * B
//        0.0,       0.0,       0.0,       1.0    // A' = A (no change)
//    ]
//
//
//    // 4. Call vImageMatrixMultiply_ARGBFFFF to perform the multiplication.
//    var bgColor: [Float] = [0, 0, 0, 0] // Background color (not used in this case, but required)
//
////    let error = vImageMatrixMultiply_ARGBFFFF(&sourceBuffer, &destinationBuffer, &matrix, &bgColor, vImage_Flags(kvImageNoFlags), .min)
////
////    if error != kvImageNoError {
////        print("Error: vImageMatrixMultiply_ARGBFFFF failed with error code \(error)")
////        return nil
////    }
//
//    // 5. Convert back to BGRA if necessary.  Since the original image was BGRA, we convert back to it.
//
////    var outputPixelBuffer: CVPixelBuffer?
////
////    if pixelFormatType == kCVPixelFormatType_32BGRA {
////        let attrs = [
////            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
////            kCVPixelBufferWidthKey as String: width,
////            kCVPixelBufferHeightKey as String: height,
////        ] as CFDictionary
////
////        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &outputPixelBuffer)
////        guard status == kCVReturnSuccess, let pixelBuffer = outputPixelBuffer else {
////            print("Error: Could not create destination pixel buffer.")
////            return nil
////        }
////
////        CVPixelBufferLockBaseAddress(pixelBuffer, [])
////        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
////
////        guard let outputBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
////            print("Error: Could not get base address of output pixel buffer.")
////            return nil
////        }
////
////        let outputBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
////
////        var outputBuffer = vImage_Buffer(data: outputBaseAddress,
////                                               height: vImagePixelCount(height),
////                                               width: vImagePixelCount(width),
////                                               rowBytes: outputBytesPerRow)
////
////        // Convert from ARGB -> BGRA
////        var permuteMap: [UInt8] = [2, 1, 0, 3] // ARGB -> BGRA
////        vImagePermuteChannels_ARGB8888(&destinationBuffer, &outputBuffer, &permuteMap, vImage_Flags(kvImageNoFlags))
////
////        return pixelBuffer
////    } else {
////        // if not BGRA, return destPixelBuffer as is (in ARGB)
////        return destinationPixelBuffer
////    }
//}
//
