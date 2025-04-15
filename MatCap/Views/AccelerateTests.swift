//
//  AccelerateTests.swift
//  MatCap
//
//  Created by Treata Norouzi on 2/10/25.
//

import Accelerate
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

func mulImage1(with pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
    // Lock the base address of the pixel buffer. This gives you direct memory access.
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) } // Ensure it's unlocked

    // Get basic information about the buffer.
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)

    // Check for nil baseAddress
    guard let baseAddressUnsafeMutablePointer = baseAddress else {
        print("Error: Could not get base address of pixel buffer.")
        return nil
    }

    // Determine pixel format. Assuming BGRA.
    let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
    guard pixelFormatType == kCVPixelFormatType_32BGRA else {
        print("Error: Pixel format is not BGRA. Expected kCVPixelFormatType_32BGRA ((kCVPixelFormatType_32BGRA)), but got (pixelFormatType).")
        return nil
    }

    // Create a new pixel buffer to hold the result
    var outputPixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &outputPixelBuffer)

    guard status == noErr, let outputBuffer = outputPixelBuffer else {
        print("Error: Could not create output pixel buffer.")
        return nil
    }

    // Lock the base address of the output pixel buffer
    CVPixelBufferLockBaseAddress(outputBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(outputBuffer, .readOnly) } // Ensure it's unlocked

    let outputBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer)!
    
    // Define scale factor
    let scale: UInt32 = 255

    // Set up vImage buffers
    var srcBuffer = vImage_Buffer(data: baseAddressUnsafeMutablePointer,
                                  height: vImagePixelCount(height),
                                  width: vImagePixelCount(width),
                                  rowBytes: bytesPerRow)
    
    var dstBuffer = vImage_Buffer(data: outputBaseAddress,
                                  height: vImagePixelCount(height),
                                  width: vImagePixelCount(width),
                                  rowBytes: bytesPerRow)

    // Scale the source image by 255.0
//    let error = vImageScale_ARGBFFFF(&srcBuffer, &dstBuffer, nil, scale, vImage_Flags(kvImageNoFlags))

//    if error != kvImageNoError {
//        print("Error scaling image: (error)")
//        return nil
//    }

    return outputBuffer
}

// MARK: - https://www.netguru.com/blog/accelerate-simd-in-image-processing-introduction

// https://github.com/ernichechelski
func mulImage2(with pixelBuffer: CVPixelBuffer) -> CGImage? {
    
    // Get basic information about the buffer.
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
    
    
    // Change these coefficient constants and check result!
            let redCoefficient: Float = 0.2126
            let greenCoefficient: Float = 0.7152
            let blueCoefficient: Float = 0.0722
            // Divisior is used for normalisation.
            // By using this value we take care about cases when a computed pixel is above the displayable value
            // (for example in RGB format, color (255,250,700) is invalid)
            let divisor: Int32 = 1/*0x1000*/
            let fDivisor = Float(divisor)
            
//            // Each pixel will be multiplied by these values.
//            var coefficientsMatrix_ = [
//                Int16(redCoefficient * fDivisor),
//                Int16(greenCoefficient * fDivisor),
//                Int16(blueCoefficient * fDivisor)
//            ]
    var coefficientsMatrix = [
        Int16(255),
        Int16(255),
        Int16(255)
    ]
            let preBias: [Int16] = [0, 0, 0, 0] // These values will be added before processing to each channel of a pixel.
            let postBias: Int32 = 0 // This value will be added to each pixel at the end of processing.
            
    
    
    // Create a destination CVPixelBuffer in ARGB format (for vImageMatrixMultiply_ARGB8888ToPlanar8)
//    var destPixelBuffer: CVPixelBuffer?
//    let destPixelFormatType = kCVPixelFormatType_32ARGB /*kCVPixelFormatType_32ARGB*/
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
    
    
    
    var destinationBuffer: vImage_Buffer = vImage_Buffer()
    destinationBuffer.height = UInt(height)
    destinationBuffer.width = UInt(width)
    destinationBuffer.rowBytes = bytesPerRow
    destinationBuffer.data = baseAddress

    
    let map: [UInt8] = [2, 1, 0, 3]
    vImagePermuteChannels_RGB888(&destinationBuffer, &destinationBuffer, map, vImage_Flags(kvImageNoFlags))
    
            // Fill our temporary buffer with initial data
            var tmpBuffer = vImage_Buffer()
            vImageBuffer_Init(&tmpBuffer,
                              destinationBuffer.height,
                              destinationBuffer.width,
                              32/*cgImageFormat.bitsPerPixel*/,
                              vImage_Flags(kvImageNoFlags))
            // Fill our temporary buffer with initial data
            vImageCopyBuffer(&destinationBuffer,
                             &tmpBuffer,
                             32,
                             vImage_Flags(kvImageNoFlags))
            // Produce single channel data.
            vImageMatrixMultiply_ARGB8888ToPlanar8(&tmpBuffer,
                                                    &destinationBuffer,
                                                    &coefficientsMatrix,
                                                    divisor,
                                                    preBias,
                                                    postBias,
                                                    vImage_Flags(kvImageNoFlags))

            free(tmpBuffer.data) // Skip this line, and app will crash!

    
    // MARK: From monochannel to quad
    
    let monoFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceRGB()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        var format = monoFormat

    var error = vImage_Error()
        let cgImage = vImageCreateCGImageFromBuffer(&destinationBuffer,
                                                    &format,
                                                    nil,
                                                    nil,
                                                    vImage_Flags(kvImageNoFlags),
                                                    &error)

//        if let cgImage = cgImage, error == kvImageNoError {
//            DispatchQueue.main.async {
//                self.imageView.image = UIImage(cgImage: cgImage.takeRetainedValue())
//            }
//        }
    
//    vDSP.multiply(255.0, pixelBuffer)
//    print(cgImage?.takeRetainedValue())
    return cgImage?.takeRetainedValue()
}

// MARK: - Playground

// 8bit
func doStuff(with pixelBuffer: CVPixelBuffer) -> CGImage? {
//    guard let inProvider = image.dataProvider else { return }
//    let providerCopy = inProvider.data
//    let inBitmapData = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(providerCopy))
//    
//    var inBuffer: vImage_Buffer = vImage_Buffer(data: inBitmapData, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    var inBuffer: vImage_Buffer = vImage_Buffer()
    inBuffer.data = CVPixelBufferGetBaseAddress(pixelBuffer)
    inBuffer.rowBytes = bytesPerRow
    inBuffer.width = UInt(width)
    inBuffer.height = UInt(height)
    
    let pixelBuffer = malloc(bytesPerRow * height)
    
    var midBuffer = vImage_Buffer(data: pixelBuffer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    var outBuffer = vImage_Buffer(data: pixelBuffer, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)
    
    // Kernel close to Apple's example in their vImage Programming Guide

    let kernel_:[Int16] = [
        -2, -2, 1,
        -2,  6, 0,
         1,  0, 0
    ]
    let kernel:[Int16] = [
        100/2, 100/2, 1,
        100/2, 100/2, 0,
        1,     0, 0
    ]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var backgroundColor : Array<UInt8> = [0,0,0,0]
    let fillBackground: vImage_Flags = UInt32(kvImageBackgroundColorFill)
    let size = CGSize(width: CGFloat(width), height: CGFloat(height))
    
    vImageConvolve_ARGB8888(&inBuffer, &midBuffer, nil, 0, 0, kernel, 3, 3, 3, &backgroundColor, fillBackground)
    
    vImageRotate_ARGB8888(&midBuffer, &inBuffer, nil, 20, &backgroundColor, fillBackground)
    
    vImageHorizontalReflect_ARGB8888(&inBuffer, &outBuffer, fillBackground)
    
    guard let context = CGContext(data: outBuffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: outBuffer.rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
    
    let outCGimage = context.makeImage()

    return outCGimage
}



// TODO: - Read -
//https://developer.apple.com/documentation/accelerate/1498226-vimagebuffer_initwithcvpixelbuff?language=objc
// https://developer.apple.com/documentation/accelerate/1498236-vimagebuffer_copytocvpixelbuffer





import Accelerate

func mulImage3(with pixelBuffer: CVPixelBuffer) -> CGImage? {
    // Lock the base address of the pixel buffer. This gives you direct memory access.
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) } // Ensure it's unlocked
    
    
    // Get basic information about the buffer.
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
    
    
    // Check for nil baseAddress
    guard let baseAddressUnsafeMutablePointer = baseAddress else {
        print("Error: Could not get base address of pixel buffer.")
        return nil
    }

    // Determine pixel format.  This is crucial for correct access.  Assuming BGRA.
    let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
    guard pixelFormatType == kCVPixelFormatType_32BGRA else {
        print("Error: Pixel format is not BGRA. Expected kCVPixelFormatType_32BGRA (\(kCVPixelFormatType_32BGRA)), but got \(pixelFormatType).")
        return nil
    }
    // Access the pixel data. We treat it as an array of Float32 (bytes). Each pixel is BGRA, hence 4 bytes per pixel.
    let buffer = baseAddressUnsafeMutablePointer.assumingMemoryBound(to: Float32.self)
    
    

    // Prepare coefficients and biases
    var coefficientsMatrix: [Int16] = [Int16(255), Int16(255), Int16(255)]
    let preBias: [Int16] = [0, 0, 0, 0]
    let postBias: Int32 = 0

    // Create a vImage_Buffer for the destination (ARGB format)
    var destinationBuffer = vImage_Buffer()
    destinationBuffer.data = malloc(height * width * 4) // Allocate memory for ARGB
    destinationBuffer.rowBytes = width * 4
    destinationBuffer.width = UInt(width)
    destinationBuffer.height = UInt(height)

    
    // Initialize source buffer (BGRA)
    var sourceBuffer = vImage_Buffer(data: buffer, // destinationBuffer, baseAddressUnsafeMutablePointer or what?
                                     height: UInt(height),
                                     width: UInt(width),
                                     rowBytes: bytesPerRow)

    let map: [UInt8] = [2, 1, 0, 3]
    // Convert BGRA to ARGB
//    vImageConvert_BGRA8888toARGB8888(&sourceBuffer, &destinationBuffer, vImage_Flags(kvImageNoFlags))
    vImagePermuteChannels_ARGBFFFF(&sourceBuffer, &destinationBuffer, map, vImage_Flags(kvImageNoFlags))
    
    // Create a temporary buffer for processing
    var tmpBuffer = vImage_Buffer()
    vImageBuffer_Init(&tmpBuffer,
                      destinationBuffer.height,
                      destinationBuffer.width,
                      32, // bits per pixel
                      vImage_Flags(kvImageNoFlags))

    // Copy data from destination buffer to temporary buffer
    vImageCopyBuffer(&destinationBuffer,
                     &tmpBuffer,
                     32,
                     vImage_Flags(kvImageNoFlags))

    // Perform matrix multiplication
    let divisor: Int32 = 1 // Set divisor appropriately based on your needs
    vImageMatrixMultiply_ARGB8888ToPlanar8(&tmpBuffer,
                                            &destinationBuffer,
                                            &coefficientsMatrix,
                                            divisor,
                                            preBias,
                                            postBias,
                                            vImage_Flags(kvImageNoFlags))

    // Free temporary buffer data after use
    free(tmpBuffer.data)
    
    // Here you would typically convert 'destinationBuffer' back to CGImage if needed.
    
    // Free allocated memory for destination buffer
    free(destinationBuffer.data)

    return nil // Return the appropriate CGImage or nil if not created
}
