/*
 CoreImageExtensions.swift
 MatCap

 Created by Treata Norouzi on 2/6/25.
*/

import CoreImage
import ImageIO
import UniformTypeIdentifiers
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import SwiftUI

extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(
            self, from: self.extent
            /*format: .RGBA16, colorSpace: .init(name: "displayP3"), deferred: false*/
        ) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
    
    /// Returns a resized image.
    func resized(to size: CGSize) -> CIImage {
        let outputScaleX = size.width / extent.width
        let outputScaleY = size.height / extent.height
        var outputImage = self.transformed(by: CGAffineTransform(scaleX: outputScaleX, y: outputScaleY))
        outputImage = outputImage.transformed(
            by: CGAffineTransform(translationX: -outputImage.extent.origin.x, y: -outputImage.extent.origin.y)
        )
        return outputImage
    }
    
    var rgbToBGR: CIImage? {
        // TODO: Switch to Metal if necessary
        let swapKernel = CIColorKernel(source: "kernel vec4 swapRedAndGreenAmount(__sample s) { return s.bgra; }")
        return swapKernel?.apply(extent: (self.extent), arguments: [self as Any])
    }
}

extension CIContext {
    /// Renders an image to a new pixel buffer.
    func render(_ image: CIImage, pixelFormat: OSType) -> CVPixelBuffer? {
        var output: CVPixelBuffer!
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(image.extent.width),
            Int(image.extent.height),
            pixelFormat,
            nil,
            &output
        )
        guard status == kCVReturnSuccess else {
            return nil
        }
        render(image, to: output)
        return output
    }

    /// Writes the image as a PNG.
    func writePNG(_ image: CIImage, to url: URL) {
        let outputCGImage = createCGImage(image, from: image.extent)!
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            fatalError("Failed to create an image destination.")
        }
        CGImageDestinationAddImage(destination, outputCGImage, nil)
        CGImageDestinationFinalize(destination)
    }
}

// MARK: — UIImage

// https://medium.com/@yiweini/ios-coreml-project-with-open-nsfw-model-516bcedd8381
extension UIImage {
    /// Generates `CVPixelBuffer` for an `UIImage`
//    func buffer(width: Int, height: Int,
//                pixelFormat: OSType = kCVPixelFormatType_32BGRA) -> CVPixelBuffer? {
//        var pixelBuffer: CVPixelBuffer? = nil
////        let width = 256
////        let height = 256
//        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
//             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
//        
//        CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormat, attrs, &pixelBuffer)
//        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue:0))
//        
//        let colorspace = CGColorSpaceCreateDeviceRGB()
//        let bitmapContext = CGContext(data:
//                CVPixelBufferGetBaseAddress(pixelBuffer!),
//                width: width,
//                height: height,
//                bitsPerComponent: 8,
//                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
//                space: colorspace,
//                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
//        bitmapContext.draw(self.cgImage!, in:
//                CGRect(x: 0, y: 0, width: width, height: height))
//        return pixelBuffer
//    }
    
    /// Generates `CVPixelBuffer` for a `UIImage`, respecting its orientation
    func buffer(width: Int, height: Int,
                pixelFormat: OSType = kCVPixelFormatType_32BGRA,
                orientation: UIImage.Orientation) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormat, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: colorspace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
//        // Use the image's orientation if none is provided
//        let effectiveOrientation = orientation ?? self.imageOrientation
        
        // Adjust the context transform based on orientation
        switch orientation {
        case .up:
            // Default, no transform needed
            break
        case .down:
            context.translateBy(x: CGFloat(width), y: CGFloat(height))
            context.rotate(by: .pi)
        case .left:
            context.translateBy(x: 0, y: CGFloat(height))
            context.rotate(by: -.pi / 2)
        case .right:
            context.translateBy(x: CGFloat(width), y: 0)
            context.rotate(by: .pi / 2)
        case .upMirrored:
            context.translateBy(x: CGFloat(width), y: 0)
            context.scaleBy(x: -1, y: 1)
        case .downMirrored:
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: -1, y: 1)
        case .leftMirrored:
            context.translateBy(x: CGFloat(width), y: CGFloat(height))
            context.rotate(by: .pi / 2)
            context.scaleBy(x: -1, y: 1)
        case .rightMirrored:
            context.rotate(by: -.pi / 2)
            context.scaleBy(x: -1, y: 1)
        @unknown default:
            break
        }
        
        // Draw the image into the adjusted context
        context.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}

/// Copies to clipboard as PNG
func copyImageToClipboard(uiImage: UIImage? = nil) {
    // Get the UIImage to copy.  Priority: dynamically loaded, then original
    guard let imageToCopy = uiImage ?? UIImage(named: "example") else { // Fallback
        print("No image available to copy.")
        return
    }

    guard let pngData = imageToCopy.pngData() else {
        print("Failed to convert image to PNG data.")
        return
    }

    UIPasteboard.general.setData(pngData, forPasteboardType: "public.png") // Use "public.png"
    print("Image copied to clipboard as PNG!")
}
