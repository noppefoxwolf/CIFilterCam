import SwiftUI
import CoreMedia
import AVFoundation
import Shared
import Defaults

struct ControllView: View {
    @StateObject var viewModel: ControlViewModel = .init()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            SampleBufferDisplayView(sampleBuffer: viewModel.sampleBuffer)
                .background(Color.black)
            Grid {
                GridRow {
                    Picker(selection: viewModel.$deviceID) {
                        ForEach(viewModel.cameras) { camera in
                            Text(camera.name)
                                .tag(camera.id)
                        }
                    } label: {
                        Text("Camera:")
                    }
                }
                
                HStack {
                    Picker(selection: viewModel.$filter) {
                        ForEach(viewModel.filters, id: \.id) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    } label: {
                        Text("Filters:")
                    }
                    Toggle("Bypass", isOn: viewModel.$isBypass)
                        .toggleStyle(.checkbox)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("OK")
                }
            }.padding()
        }.onAppear {
            viewModel.startRunning()
        }.onDisappear {
            viewModel.stopRunning()
        }
    }
}

class ControlViewModel: NSObject, ObservableObject {
    @Published var sampleBuffer: CMSampleBuffer? = nil
    
    @Default(.deviceID) var deviceID: String
    @Published var cameras: [Camera] = []
    
    @Default(.isBypass) var isBypass
    @Default(.filter) var filter: Filter
    let filters: [Filter] = Filter.allCases
    
    let input: AVCaptureDeviceInput = {
        let device = AVCaptureDevice.DiscoverySession.extensionDevice()
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
    
    override init() {
        super.init()
        let availableDevices = AVCaptureDevice
            .DiscoverySession
            .devicesWithoutExtension()
            .map({ Camera(id: $0.uniqueID, name: $0.localizedName) })
        
        cameras = [.none] + availableDevices
    }
    
    func startRunning() {
        session.startRunning()
    }
    
    func stopRunning() {
        session.stopRunning()
    }
}

extension ControlViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.sampleBuffer = sampleBuffer
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
