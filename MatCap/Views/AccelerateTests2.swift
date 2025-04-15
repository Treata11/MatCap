//
//  AccelerateTests2.swift
//  MatCap
//
//  Created by Treata Norouzi on 2/10/25.
//

import CoreImage
import Accelerate

//let cookiesURL = NSURL(fileURLWithPath: Bundle.main.pathForImageResource("boobie.png")!)
//let imageSource = CGImageSourceCreateWithURL(cookiesURL, nil)
//let image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)!
//
//let nsImage = NSImage(cgImage: image, size: size)
//var frame = NSMakeRect(0, 0, 0, 0)
//frame.size = size
//let playgroundView = NSImageView(frame: frame)
//playgroundView.image = nsImage

let colorSpace = CGColorSpaceCreateDeviceRGB()
var backgroundColor : Array<UInt8> = [0,0,0,0]
let fillBackground: vImage_Flags = UInt32(kvImageBackgroundColorFill)

func doStuff(with image: CGImage) -> CGImage? {
    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow
    
    guard let inProvider = image.dataProvider else { return nil }
    let providerCopy = inProvider.data
    let inBitmapData = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(providerCopy))
    
    var inBuffer: vImage_Buffer = vImage_Buffer(data: inBitmapData, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    let pixelBuffer = malloc(bytesPerRow * height)
    
    var outBuffer = vImage_Buffer(data: pixelBuffer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    // Kernel close to Apple's example in their vImage Programming Guide

    let kernel_:[Int16] = [
        -2, -2, 1,
        -2,  6, 0,
         1,  0, 0
    ]
    let kernel_2:[Int16] = [
        255, 255, 1,
        255, 255, 1,
        0,     0, 1,
    ]
    var kernel: [Int16] = [255, 255, 255, 1]
    
    vImageConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, kernel, 3, 3, 3, &backgroundColor, fillBackground)
    
//    vImageRotate_ARGB8888(&outBuffer, &inBuffer, nil, 20, &backgroundColor, fillBackground)
    
//    vImageHorizontalReflect_ARGB8888(&inBuffer, &outBuffer, fillBackground)
    
    guard let context = CGContext(data: outBuffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: outBuffer.rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
    
    let outCGimage = context.makeImage()
    
    free(pixelBuffer)
    
    return outCGimage
}

// New
func doStuff2(with image: CGImage) -> CGImage? {
    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow
    
    guard let inProvider = image.dataProvider else { return nil }
    let providerCopy = inProvider.data
    let inBitmapData = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(providerCopy))
    
    var inBuffer: vImage_Buffer = vImage_Buffer(data: inBitmapData, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    // Allocate memory for the output buffer
    let pixelBuffer = malloc(bytesPerRow * height)!
    
    var outBuffer: vImage_Buffer = vImage_Buffer(data: pixelBuffer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    // Create a scaling factor for RGB channels (255.0)
    var scale: [Int16] = [255, 255, 255, 1] // Multiply RGB by 255, keep Alpha at 1
    
    // Multiply RGB channels by 255.0
    let error = vImageScale_ARGB8888(&inBuffer, &outBuffer, &scale, vImage_Flags(kvImageHighQualityResampling))
    
    guard error == kvImageNoError else {
        free(pixelBuffer)
        return nil
    }
    
    // Create a CGContext to convert the output buffer back to CGImage
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    guard let context = CGContext(data: outBuffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: outBuffer.rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        free(pixelBuffer)
        return nil
    }
    
    let outCGimage = context.makeImage()
    
    // Free the allocated pixel buffer
    free(pixelBuffer)
    
    return outCGimage
}

func doStuff3(with image: CGImage) -> CGImage? {
    let size: CGSize = .init(width: 256, height: 256)
    
    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow

    // Define the image format
    var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                      bitsPerPixel: 32,
                                      colorSpace: nil,
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                                      version: 0,
                                      decode: nil,
                                      renderingIntent: .defaultIntent)

    var error: vImage_Error

    // Create and initialize the source buffer
    var sourceBuffer = vImage_Buffer()
    defer { sourceBuffer.data.deallocate() }
    error = vImageBuffer_InitWithCGImage(&sourceBuffer,
                                         &format,
                                         nil,
                                         image,
                                         vImage_Flags(kvImageNoFlags))
    guard error == kvImageNoError else { return nil }

    // Create and initialize the destination buffer
    var destinationBuffer = vImage_Buffer()
    error = vImageBuffer_Init(&destinationBuffer,
                              vImagePixelCount(size.height),
                              vImagePixelCount(size.width),
                              format.bitsPerPixel,
                              vImage_Flags(kvImageNoFlags))
    guard error == kvImageNoError else { return nil }

    // Scale the image
    error = vImageScale_ARGB8888(&sourceBuffer,
                                 &destinationBuffer,
                                 nil,
                                 vImage_Flags(kvImageHighQualityResampling))
    guard error == kvImageNoError else { return nil }

    // Create a CGImage from the destination buffer
    guard let resizedImage =
        vImageCreateCGImageFromBuffer(&destinationBuffer,
                                      &format,
                                      nil,
                                      nil,
                                      vImage_Flags(kvImageNoAllocate),
                                      &error)?.takeRetainedValue(),
        error == kvImageNoError
    else {
        return nil
    }

    return resizedImage
}


func doStuff4(with image: CGImage) -> CGImage? {
    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow
    
    guard let inProvider = image.dataProvider else { return nil }
    let providerCopy = inProvider.data
    let inBitmapData = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(providerCopy))
    
    var inBuffer: vImage_Buffer = vImage_Buffer(data: inBitmapData, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    let pixelBuffer = malloc(bytesPerRow * height)
    
    guard let pixelBufferPointer = pixelBuffer else { return nil }
    
    var outBuffer: vImage_Buffer = vImage_Buffer(data: pixelBufferPointer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)

    // Create a constant array for the multiplication factors (R, G, B)
    let multiplier: [Int16] = [1, 1, 1]
    let preBias: [Int16] = [0, 0, 0, 0] // These values will be added before processing to each channel of a pixel.
    let postBias: Int32 = 0 // This value will be added to each pixel at the end of processing.
    
    // Apply the multiplication using vImage
    let error = vImageMatrixMultiply_ARGB8888(&inBuffer,
                                               &outBuffer,
                                               multiplier,
                                               1,
                                              preBias,
                                              nil,
                                               vImage_Flags(kvImageNoFlags))
    
    guard error == kvImageNoError else {
        free(pixelBuffer)
        return nil
    }
    
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        free(pixelBuffer)
        return nil
    }
    
    guard let context = CGContext(data: outBuffer.data,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: outBuffer.rowBytes,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        free(pixelBuffer)
        return nil
    }
    
    let outCGimage = context.makeImage()
    
    free(pixelBuffer)
    
    return outCGimage
}

public func doStuff5(with image: CGImage) -> CGImage? {
    let size = CGSize(width: 256, height: 256)
    let scale: CGFloat = 1

//    guard size.width >= 1 && size.height >= 1 else {
//        return image
//    }
//    guard let cgImage = image.cgImage else {
//        return image
//    }

    let width = Int(size.width)
    let height = Int(size.height)
    let bytesPerRow = image.bytesPerRow
    
    guard let inProvider = image.dataProvider else { return nil }
    let providerCopy = inProvider.data
    let inBitmapData = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(providerCopy))
    var inBuffer: vImage_Buffer = vImage_Buffer(data: inBitmapData, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    // Allocate memory for the output buffer
    let pixelBuffer = malloc(bytesPerRow * height)!
    
    var outBuffer: vImage_Buffer = vImage_Buffer(data: pixelBuffer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
//    let space = CGColorSpaceCreateDeviceRGB()
    guard let space = CGColorSpace(name: CGColorSpace.sRGB) else {
//        free(pixelBuffer)
        return nil
    }
//    let bitmapInfo: CGImageAlphaInfo = isOpaque ? .noneSkipLast : .premultipliedLast
    let bitmapInfo: CGImageAlphaInfo = .noneSkipLast
    guard var inputContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: space, bitmapInfo: bitmapInfo.rawValue) else {
        return image
    }

    inputContext.draw(image, in: CGRect(origin: .zero, size: size))
    var input = vImage_Buffer(data: inputContext.data,
                              height: UInt(inputContext.height),
                              width: UInt(inputContext.width),
                              rowBytes: inputContext.bytesPerRow)

    guard var outputContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: space, bitmapInfo: bitmapInfo.rawValue) else {
        return image
    }

//    let hasBlur = blurRadius > CGFloat.ulpOfOne
//    let hasSaturationChange = abs(saturationDeltaFactor - 1) > CGFloat.ulpOfOne

        var output = vImage_Buffer(data: outputContext.data,
                                   height: UInt(outputContext.height),
                                   width: UInt(outputContext.width),
                                   rowBytes: outputContext.bytesPerRow)

        // Saturation
            let divisor: CGFloat = 255
            let matrix = [
                255,  255,  255,  0,
                255,  255,  255,  0,
                255,  255,  255,  0,
                0, 0, 0,  1
            ].map { Int16($0) }
//        .map { Int16(round($0 * divisor)) }

//            if hasBlur {
//                swap(&input, &output)
//                swap(&inputContext, &outputContext)

                vImageMatrixMultiply_ARGB8888(&input, &output, matrix, Int32(1/255), nil, nil, vImage_Flags(kvImageNoFlags))
//            }

//    if let tintColor = tintColor {
//        outputContext.setFillColor(tintColor.cgColor)
        outputContext.fill(CGRect(origin: .zero, size: size))
//    }

    guard let outputImage = outputContext.makeImage() else {
        return image
    }
    
    return outputImage
}

/// DONE!
func doStuff6(with image: CGImage) -> CGImage? {
    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow
    
    guard let inProvider = image.dataProvider else { return nil }
    let providerCopy = inProvider.data
    let inBitmapData = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(providerCopy))
    
    var inBuffer: vImage_Buffer = vImage_Buffer(data: inBitmapData, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    let pixelBuffer = malloc(bytesPerRow * height)
    
    var outBuffer = vImage_Buffer(data: pixelBuffer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    let divisor: CGFloat = 255
    let matrix = [
        255,  1,  1,  0,
        1,  255,  1,  0,
        1,  1,  255,  0,
        0, 0, 0,  1
    ].map { Int16($0) }
//        .map { Int16(round($0 * divisor)) }

//            if hasBlur {
//                swap(&input, &output)
//                swap(&inputContext, &outputContext)

    vImageMatrixMultiply_ARGB8888(&inBuffer, &outBuffer, matrix, Int32(1), nil, nil, vImage_Flags(kvImageNoFlags))
    
    guard let context = CGContext(data: outBuffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: outBuffer.rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
    
    let outCGimage = context.makeImage()
    
    free(pixelBuffer)
    
    return outCGimage
}

// MARK: -
// Swift (Example)
import CoreML
import Vision

import CoreML
import Vision
import CoreGraphics

// Doesn't work?
func processCoreMLOutput(pixelBuffer: CVPixelBuffer) -> CGImage? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)

    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Assuming Float32 RGB values, adjust as needed
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)  // Or .none if no alpha
    guard let context = CGContext(data: baseAddress,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 32, // Float32 = 4 bytes per component
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
        return nil
    }

    // Create an image from the pixel buffer
    guard let cgImage = context.makeImage() else {
        return nil
    }

    // Apply the scaling (multiplication by 255) to convert Float 0-1 range to byte range 0-255
    let scaledImage = scaledCGImage(cgImage, scaleFactor: 255.0)

    print("Scaled Image: \(String(describing: scaledImage))")
    return scaledImage
}

// Helper function to scale the colors in a CGImage
private func scaledCGImage(_ image: CGImage, scaleFactor: CGFloat) -> CGImage? {
    let width = image.width
    let height = image.height

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue // Or .none depending on original image format
    let bytesPerRow = width * 4 // 4 bytes per pixel (RGBA)
    let bitsPerComponent = 8  // Each color component (R, G, B, A) is 8 bits (1 byte)
    let bitsPerPixel = 32      // 4 components * 8 bits per component

    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo) else {
        return nil
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

    guard let pixelData = context.data else {
        return nil
    }
    let pixels = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)

    // Apply the scaling to convert from Float32 0-1 range to UInt8 0-255 range
    for i in 0..<(width * height * 4) {
        // Assuming pixelData is Float32, adjust if it's something else
        let scaledValue = min(255.0, max(0.0, CGFloat(pixels[i]) * scaleFactor))
        pixels[i] = UInt8(scaledValue)
    }

    guard let outputImage = context.makeImage() else {
        return nil
    }

    return outputImage
}

// MARK: - Tests:

import SwiftUI

struct TestsView2: View {
    @State private var cgImage: CGImage?
    
    var body: some View {
        VStack {
            Button("Accelerate") {
                self.cgImage = doStuff(with: (UIImage(named: "example")?.cgImage)!)
            }
            if let cgImage = cgImage {
                Image(cgImage, scale: 1, label: Text("Accelerated"))
            }
        }
    }
}

// MARK: - Roughness

import CoreImage
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

func extractChannelToGrayscale(cgImage: CGImage, channel: Int) -> CGImage? {
    let ciImage = CIImage(cgImage: cgImage)

    let filterName: String
    switch channel {
    case 0: // Red
        filterName = "CIRedToAlpha"
    case 1: // Green
        filterName = "CIGreenToAlpha"
    case 2: // Blue
        filterName = "CIBlueToAlpha"
    default:
        print("Invalid channel. Defaulting to Red.")
        filterName = "CIRedToAlpha"
    }

    guard let filter = CIFilter(name: filterName) else {
        print("Failed to create filter: \(filterName)")
        return nil
    }

    filter.setValue(ciImage, forKey: kCIInputImageKey)

    guard let outputCIImage = filter.outputImage else {
        print("Failed to get output image from filter")
        return nil
    }

    let context = CIContext() // Or use a shared context for better performance

    guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
        print("Failed to create CGImage from CIImage")
        return nil
    }

    return outputCGImage
}
