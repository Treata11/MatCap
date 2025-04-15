/*
 Camera.swift
 MatCap

 Created by Treata Norouzi on 2/6/25.
*/

import AVFoundation
import CoreImage
import OSLog
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

fileprivate let logger = Logger(subsystem: "com.apple.treata.materialmap", category: "Camera")

/**
 A model to process upon all of the captured frames
 */
final class LiveCamera: NSObject {
    let captureSession = AVCaptureSession()
    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    private var sessionQueue: DispatchQueue!

    var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice = captureDevice else { return }
            logger.debug("Using capture device: \(captureDevice.localizedName)")
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }

    var isRunning: Bool {
        captureSession.isRunning
    }

    var isUsingFrontCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return frontCaptureDevices.contains(captureDevice)
    }

    private var addToPreviewStream: ((CIImage) -> Void)?

    var isPreviewPaused = false

    lazy var previewStream: AsyncStream<CIImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { ciImage in
                if !self.isPreviewPaused {
                    continuation.yield(ciImage)
                }
            }
        }
    }()

    override init() {
        super.init()

        sessionQueue = DispatchQueue(label: "com.apple.treata.materialmap")
        captureDevice = availableCaptureDevices.first ?? AVCaptureDevice.default(for: .video)
    }

    private func configureCaptureSession() -> Bool {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }

        captureSession.sessionPreset = .hd1280x720

        guard
            let captureDevice = captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            logger.error("Failed to obtain video input.")
            return false
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))

        guard captureSession.canAddInput(deviceInput) else {
            logger.error("Unable to add device input to capture session.")
            return false
        }
        guard captureSession.canAddOutput(videoOutput) else {
            logger.error("Unable to add video output to capture session.")
            return false
        }

        captureSession.addInput(deviceInput)
        captureSession.addOutput(videoOutput)

        self.deviceInput = deviceInput
        self.videoOutput = videoOutput

        updateVideoOutputConnection()

        isCaptureSessionConfigured = true
        return true
    }

    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            logger.debug("Camera access authorized.")
            return true
        case .notDetermined:
            logger.debug("Camera access not determined.")
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            return status
        case .denied:
            logger.debug("Camera access denied.")
            return false
        case .restricted:
            logger.debug("Camera library access restricted.")
            return false
        @unknown default:
            return false
        }
    }

    private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            logger.error("Error getting capture device input: \(error.localizedDescription)")
            return nil
        }
    }

    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        guard isCaptureSessionConfigured else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }

        if let deviceInput = deviceInputFor(device: captureDevice) {
            if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        }

        updateVideoOutputConnection()
    }

    private func updateVideoOutputConnection() {
        if let videoOutput = videoOutput, let videoOutputConnection = videoOutput.connection(with: .video) {
            if videoOutputConnection.isVideoMirroringSupported {
                videoOutputConnection.isVideoMirrored = isUsingFrontCaptureDevice
            }
        }
    }

    func start() async {
        let authorized = await checkAuthorization()
        guard authorized else {
            logger.error("Camera access was not authorized.")
            return
        }

        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async { [self] in
                    self.captureSession.startRunning()
                }
            }
            return
        }

        sessionQueue.async { [self] in
            guard self.configureCaptureSession() else { return }
            self.captureSession.startRunning()
        }
    }

    func stop() {
        guard isCaptureSessionConfigured else { return }

        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
}

extension LiveCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            return
        }

        // Match rotation to the preview layer, if present
        if let previewConnection = captureSession.connections.first(where: { $0 != connection }),
           connection.isVideoRotationAngleSupported(previewConnection.videoRotationAngle) {
            connection.videoRotationAngle = previewConnection.videoRotationAngle
        }

        addToPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
    }
}

// MARK: - Capture device

extension LiveCamera {
    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter( { $0.isConnected } )
            .filter( { !$0.isSuspended } )
    }

    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
        if let backDevice = backCaptureDevices.first {
            devices += [backDevice]
        }
        if let frontDevice = frontCaptureDevices.first {
            devices += [frontDevice]
        }
        return devices
    }

    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter({ $0.position == .front })
    }

    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter({ $0.position == .back })
    }

    private var allCaptureDevices: [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInTripleCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
        ]
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        return session.devices
    }
}

// MARK: - Main

//
//  Camera.swift
//  EmojiArt
//
//  Created by Treata Norouzi on 1/13/23.
//

import SwiftUI

// FIXME: Square image capture
// FIXME: Orientation ... 
// TODO: Implement custom Camera with AVCaptureSession
struct Camera: UIViewControllerRepresentable {
    var handlePickedImage: (UIImage?) -> Void
    
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(handlePickedImage: handlePickedImage, isPresented: $isPresented)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // nothing to do
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var handlePickedImage: (UIImage?) -> Void
        @Binding var isPresented: Bool

        init(handlePickedImage: @escaping (UIImage?) -> Void, isPresented: Binding<Bool>) {
            self.handlePickedImage = handlePickedImage
            self._isPresented = isPresented
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            handlePickedImage(nil)
            self.isPresented = false
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            handlePickedImage((info[.editedImage] ?? info[.originalImage]) as? UIImage)
        }
//        func imagePickerController(
//            _ picker: UIImagePickerController,
//            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
//        ) {
//            if let image = info[.originalImage] as? UIImage, let cgImage = image.cgImage {
//                handlePickedImage(UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)) // Send UIImage from the CGImage
//            } else {
//                handlePickedImage(nil) // Handle error case if CGImage cannot be created
//            }
//        }
    }
}

#Preview("Camera Representable") {
    @Previewable @State var data: Data? = nil
    @Previewable @State var isPrestented: Bool = true
    
    func handlePickedBackgroundImage(_ image: UIImage?) {
//        autozoom = true
        if let imageData = image?.pngData() {
            data = imageData
            isPrestented = false
        }
    }
    
    return Camera(
        handlePickedImage: { image in handlePickedBackgroundImage(image) },
        isPresented: $isPrestented
    )
    
}

// MARK: - To check:
// https://stackoverflow.com/questions/49609688/taking-a-square-photo-with-camera-app
// https://github.com/Mijick/Camera
// https://github.com/Yummypets/YPImagePicker/blob/2.5.1/Source/Camera/YPCameraVC.swift


