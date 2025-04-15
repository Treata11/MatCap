/*
 CamDataModel.swift
 MatCap

 Created by Treata Norouzi on 2/6/25.
 
 Abstract:
 A VM to capture camera input and process in real-time
*/

import CoreImage
import CoreML
import SwiftUI
import os

//@Observable
final class CamDataModel: ObservableObject {
    let camera = LiveCamera()
    let context = CIContext()

    /// The normal-map model.
    var model: NormalMapGenerator_CX_Lite_200000_G?

    /// A pixel buffer used as input to the model.
    let inputPixelBuffer: CVPixelBuffer

    /// The last image captured from the camera.
    var lastImage = OSAllocatedUnfairLock<CIImage?>(uncheckedState: nil)

    /// The resulting texture
    @Published var output: Image?
    
    // Create a reusable buffer to avoid allocating memory for every model invocation
    private var buffer: CVPixelBuffer!
    
    init() {

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(256),
            Int(256),
            kCVPixelFormatType_32ARGB,
            nil,
            &buffer
        )
        guard status == kCVReturnSuccess else {
            fatalError("Failed to create pixel buffer")
        }
        inputPixelBuffer = buffer

        // Decouple running the model from the camera feed since the model will run slower
        Task.detached(priority: .userInitiated) {
            await self.runModel()
        }
        Task {
            await handleCameraFeed()
        }
    }
    
    func handleCameraFeed() async {
//        let imageStream = camera.previewStream
//        for await image in imageStream {
//            lastImage.withLock({ $0 = image })
//        }
    }

    func runModel() async {
        try! loadModel()

        let clock = ContinuousClock()
        var durations = [ContinuousClock.Duration]()

        print("Going for performInference() now")
        while !Task.isCancelled {
            let image = lastImage.withLock({ $0 })
//            let image = CIImage(image: UIImage(named: "example")!) // mine
            print("Mean While, image: \(String(describing: image))\n image.pixelBuffer: \(String(describing: image?.pixelBuffer))")
            context.render(image!, to: self.buffer)
            if let pixelBuffer = image?.pixelBuffer {
                let duration = await clock.measure {
                    try? await performInference(pixelBuffer)
                }
                durations.append(duration)
            } else {
                print("image/lastImage was nil")
            }

            let measureInterval = 100
            if durations.count == measureInterval {
                let total = durations.reduce(Duration(secondsComponent: 0, attosecondsComponent: 0), +)
                let average = total / measureInterval
                print("Average model runtime: \(average.formatted(.units(allowed: [.milliseconds])))")
                durations.removeAll(keepingCapacity: true)
            }

            // Slow down inference to prevent freezing the UI
            try? await Task.sleep(for: .milliseconds(100_000))
        }
    }

    func loadModel() throws {
        print("Loading model...")

        let clock = ContinuousClock()
        let start = clock.now

        model = try NormalMapGenerator_CX_Lite_200000_G()

        let duration = clock.now - start
        print("Model loaded (took \(duration.formatted(.units(allowed: [.seconds, .milliseconds]))))")
    }
    
    

    func performInference(_ pixelBuffer: CVPixelBuffer) async throws {
        print("performInference") // mine
        guard let model else {
            print("Sth wrong with model: \(String(describing: model))")
            return
        }

        let originalSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer).resized(to: CGSize(width: 256, height: 256))
//        let inputImage = CIImage(image: UIImage(named: "example")!)!.resized(to: targetSize) // mine
        context.render(inputImage, to: inputPixelBuffer)
        let result = try model.prediction(imageTexture: inputPixelBuffer) // TODO: Rename Image_Texture
        let res = result.normalMap
//        let outputImage = CIImage(cvPixelBuffer: result.normalMap) // TODO: Rename Normal_Map
//            .resized(to: originalSize)
//            .image

        Task { @MainActor in
//            output = outputImage
            print("Output is: \n\(String(describing: output))\n\n")
        }
    }
}
