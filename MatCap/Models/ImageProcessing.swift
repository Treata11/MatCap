//
//  ImageProcessing.swift
//  MatCap
//
//  Created by Treata Norouzi on 2/18/25.
//

import Accelerate

func pixelMultiplication(by factor: Int16 = 255, for image: CGImage) -> CGImage? {
    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow
    
    guard let inProvider = image.dataProvider else { return nil }
    let providerCopy = inProvider.data
    let inBitmapData = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(providerCopy))
    
    var inBuffer: vImage_Buffer = vImage_Buffer(data: inBitmapData, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    let pixelBuffer = malloc(bytesPerRow * height)
    
    var outBuffer = vImage_Buffer(data: pixelBuffer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    let divisor: Int32 = 1
    let matrix: [Int16] = [
        factor,  1,  1,  0,
        1,  factor,  1,  0,
        1,  1,  factor,  0,
        0,  0, 0,  1
    ]
//        .map { Int16(round($0 * divisor)) }

//            if hasBlur {
//                swap(&input, &output)
//                swap(&inputContext, &outputContext)

    vImageMatrixMultiply_ARGB8888(&inBuffer, &outBuffer, matrix, divisor, nil, nil, vImage_Flags(kvImageNoFlags))
    
    guard let context = CGContext(data: outBuffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: outBuffer.rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
    
    let outCGimage = context.makeImage()
    
    free(pixelBuffer)
    
    return outCGimage
}

import CoreImage

// TODO: Use Accelerate instead if possible
func channelToGrayscale(cgImage: CGImage, channel: Channel, context: CIContext) -> CGImage? {
    let ciImage = CIImage(cgImage: cgImage)
    // Create a CIFilter for color matrix
    let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
    
    // Set the input image
    colorMatrixFilter.setValue(ciImage, forKey: kCIInputImageKey)
    
    // Define the matrix based on the channel you want to extract
    switch channel {
    case .red:
        // Extract red channel
        colorMatrixFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 1), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        
    case .green:
        // Extract green channel
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        
    case .blue:
        // Extract blue channel
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
    }
    
    // Set alpha vector to preserve alpha channel
    colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")

    // Get the output image
    guard let outputCIImage = colorMatrixFilter.outputImage else {
        fatalError("Could not get output image from filter.")
    }

//    let context = CIContext() // Or use a shared context for better performance
    
//    guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
//        print("Failed to create CGImage from CIImage")
//        return nil
//    }
    
    let colorSpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)
    guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent, format: .L8, colorSpace: colorSpace) else {
        print("Failed to create CGImage from CIImage")
        return nil
    }

    return outputCGImage
}
// Same as above
func channelToGrayscale(cgImage: CGImage, channel: Channel, invertBlue: Bool = false, context: CIContext) -> CGImage? {
    let ciImage = CIImage(cgImage: cgImage)
    // Create a CIFilter for color matrix
    let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
    
    // Set the input image
    colorMatrixFilter.setValue(ciImage, forKey: kCIInputImageKey)
    
    // Define the matrix based on the channel you want to extract
    switch channel {
    case .red:
        // Extract red channel
        colorMatrixFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 1), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        
    case .green:
        // Extract green channel
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        
    case .blue:
        // Extract blue channel
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
    }
    
    // Set alpha vector to preserve alpha channel
    colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")

    // Get the output image
    guard let outputCIImage = colorMatrixFilter.outputImage else {
        fatalError("Could not get output image from filter.")
    }

    // If we are extracting the blue channel and we want to invert it
    if channel == .blue && invertBlue {
        let invertFilter = CIFilter(name: "CIColorInvert")!
        invertFilter.setValue(outputCIImage, forKey: kCIInputImageKey)
        
        guard let invertedCIImage = invertFilter.outputImage else {
            fatalError("Could not get inverted output image from filter.")
        }

        // Use the inverted image for further processing
        return createCGImage(from: invertedCIImage, context: context)
    }
    
    return createCGImage(from: outputCIImage, context: context)
}
private func createCGImage(from ciImage: CIImage, context: CIContext) -> CGImage? {
    let colorSpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)
    
    guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent, format: .L8, colorSpace: colorSpace) else {
        print("Failed to create CGImage from CIImage")
        return nil
    }

    return outputCGImage
}

// Define an enum for channel selection
enum Channel {
    case red
    case green
    case blue
}


// MARK: -

import CoreML
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension MLMultiArray {
    
    func postProcessImage(size: Int = 256, channelCount: Int = 4) -> CGImage? {
        let rawPointer = malloc(size*size * channelCount)!
        let bytes = rawPointer.bindMemory(to: UInt8.self, capacity: size*size * channelCount)
        
        let mlArray = self.dataPointer.bindMemory(to: Float32.self, capacity: size*size * channelCount)
        for index in 0..<self.count/(channelCount) {
            bytes[index*channelCount + 0] = UInt8(max(min(mlArray[index]*255, 255), 0))
            bytes[index*channelCount + 1] = UInt8(max(min(mlArray[index + size*size]*255, 255), 0))
            bytes[index*channelCount + 2] = UInt8(max(min(mlArray[index + size*size*2]*255, 255), 0))
//            bytes[index*channelCount + 3] = UInt8(max(min(mlArray[index + size*size*3]*255, 255), 0))
        }
        
        let selftureSize = size*size * channelCount
        
        let provider = CGDataProvider(dataInfo: nil, data: rawPointer, size: selftureSize, releaseData: { (_, data, size) in
            data.deallocate()
        })!
       
        let rawBitmapInfo = CGImageAlphaInfo.none.rawValue
        let bitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        let pColorSpace = CGColorSpaceCreateDeviceRGB()

        let rowBytesCount = size * channelCount
        if let cgImage = CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: rowBytesCount, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent) {
            
            return cgImage
        } else {
            return nil
        }
    }
}
