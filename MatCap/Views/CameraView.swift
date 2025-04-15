/*
 CameraView.swift
 MatCap

 Created by Treata Norouzi on 2/6/25.
*/

import SwiftUI

struct CameraView: View {
    @StateObject private var model = CamDataModel()
    
    @State private var image: Image = Image(.brick)

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
//                    ViewfinderView(session: model.camera.captureSession)
                    Image(.brick)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height / 2).clipped()
                    
                    TextureView(image: $model.output)
                        .frame(width: 256, height: 256).clipped()
                    
                }
                .onTapGesture {
                    Task {
                        
//                        model.lastImage = Image(.brick) 
                        await model.runModel()
//                        model.performInference()
                        image = model.output ?? Image(.brick)
                    }
                }
            }
            .task {
                await model.camera.start()
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .statusBar(hidden: true)
            .ignoresSafeArea()
        }
    }
}

#Preview("CameraView") {
    CameraView()
}



// MARK: - New

import AVFoundation

class CameraManager: NSObject {
    // 1.
    private let captureSession = AVCaptureSession()
    // 2.
    private var deviceInput: AVCaptureDeviceInput?
    // 3.
    private var videoOutput: AVCaptureVideoDataOutput?
    // 4.
    private let systemPreferredCamera = AVCaptureDevice.default(for: .video)
    // 5.
    private var sessionQueue = DispatchQueue(label: "video.preview.session")
    
    private var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    private var addToPreviewStream: ((CGImage) -> Void)?
    
    lazy var previewStream: AsyncStream<CGImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { cgImage in
                continuation.yield(cgImage)
            }
        }
    }()
    
    override init() {
        super.init()
        
        Task {
            await configureSession()
            await startSession()
        }
    }
    
    // 2.
    private func configureSession() async {
        // 1.
        guard await isAuthorized,
              let systemPreferredCamera,
              let deviceInput = try? AVCaptureDeviceInput(device: systemPreferredCamera)
        else { return }
        
        // 2.
        captureSession.beginConfiguration()
        
        // 3.
        defer {
            self.captureSession.commitConfiguration()
        }
        
        // 4.
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        // 5.
        guard captureSession.canAddInput(deviceInput) else {
            print("Unable to add device input to capture session.")
            return
        }
        
        // 6.
        guard captureSession.canAddOutput(videoOutput) else {
            print("Unable to add video output to capture session.")
            return
        }
        
        // 7.
        captureSession.addInput(deviceInput)
        captureSession.addOutput(videoOutput)
        
    }
    
    // 3.
    private func startSession() async {
        /// Checking authorization
        guard await isAuthorized else { return }
        /// Start the capture session flow of data
        captureSession.startRunning()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let currentFrame = sampleBuffer.cgImage else { return }
        addToPreviewStream?(currentFrame)
    }
    
}

import CoreImage

extension CMSampleBuffer {
    
    var cgImage: CGImage? {
        let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(self)
        
        guard let imagePixelBuffer = pixelBuffer else {
            return nil
        }
        
        return CIImage(cvPixelBuffer: imagePixelBuffer).cgImage
    }
    
}


@Observable
class CamVM {
    var currentFrame: CGImage?
    private let cameraManager = CameraManager()
    
    init() {
         Task {
             await handleCameraPreviews()
         }
     }
    
    func handleCameraPreviews() async {
        for await image in cameraManager.previewStream {
            Task { @MainActor in
                currentFrame = image
            }
        }
    }
}

// MARK: View

struct CamView: View {
    
    @Binding var image: CGImage?
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width,
                           height: geometry.size.height)
            } else {
                ContentUnavailableView("No camera feed", systemImage: "xmark.circle.fill")
                    .frame(width: geometry.size.width,
                           height: geometry.size.height)
            }
        }
    }
    
}

#Preview("Cam View") {
    @Previewable @State var viewModel = CamVM()
    
    CamView(image: $viewModel.currentFrame)
}
