import SwiftUI
import CoreMedia
import Shared
import AVFoundation

struct DebugView: View {
    @StateObject var viewModel: DebugViewModel = .init()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            SampleBufferDisplayView(sampleBuffer: viewModel.sampleBuffer)
                .background(Color.black)
                .scaleEffect(x: -1)
            Button {
                dismiss()
            } label: {
                Text("OK")
            }
        }.onAppear {
            viewModel.startRunning()
        }.onDisappear {
            viewModel.stopRunning()
        }
    }
}

class DebugViewModel: NSObject, ObservableObject {
    @Published var sampleBuffer: CMSampleBuffer? = nil
    
    let input: AVCaptureDeviceInput = {
        let device = AVCaptureDevice.DiscoverySession.devicesWithoutExtension()[0]
        return try! AVCaptureDeviceInput(device: device)
    }()

    let output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA
        ]
        return output
    }()
    
    lazy var session: AVCaptureSession = {
        var session = AVCaptureSession()
        session.addInput(input)
        output.setSampleBufferDelegate(self, queue: .main)
        session.addOutput(output)
        return session
    }()
        
    func startRunning() {
        session.startRunning()
    }
    
    func stopRunning() {
        session.stopRunning()
    }
}

extension DebugViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imageBuffer = sampleBuffer.imageBuffer!
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        }
        
        let filter = CIFilter.sepiaTone()
        filter.inputImage = CIImage(cvImageBuffer: imageBuffer)
        CIContext().render(filter.outputImage!, to: imageBuffer)
        
        self.sampleBuffer = sampleBuffer
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
