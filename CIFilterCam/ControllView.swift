import SwiftUI
import CoreMedia
import AVFoundation

struct ControllView: View {
    @StateObject var viewModel: ControlViewModel = .init()
    
    var body: some View {
        VStack {
            SampleBufferDisplayView(sampleBuffer: viewModel.sampleBuffer)
                .background(Color.black)
            Grid {
                GridRow {
                    Picker(selection: $viewModel.selectedCameraID) {
                        ForEach(viewModel.cameras) { camera in
                            Text(camera.name)
                                .tag(camera.id)
                        }
                    } label: {
                        Text("Camera:")
                    }
                }
                
                HStack {
                    Picker(selection: $viewModel.selectedFilterID) {
                        ForEach(viewModel.filters) { filter in
                            Text(filter.name).tag(filter.id)
                        }
                    } label: {
                        Text("Filters:")
                    }
                    Toggle("Bypass", isOn: $viewModel.isBypass)
                        .toggleStyle(.checkbox)
                }
            }.padding()
        }.onAppear {
            viewModel.startRunning()
        }.onDisappear {
            viewModel.stopRunning()
        }
    }
}

struct Filter: Identifiable {
    var id: UUID
    var name: String
}

struct Camera: Identifiable {
    var id: String
    var name: String
}

class ControlViewModel: NSObject, ObservableObject {
    @Published var sampleBuffer: CMSampleBuffer? = nil
    
    @Published var selectedCameraID: Camera.ID = ""
    @Published var isBypass: Bool = false
    @Published var selectedFilterID: Filter.ID = UUID()
    
    @Published var cameras: [Camera] = []
    @Published var filters: [Filter] = []
    
    let input: AVCaptureDeviceInput
    
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
        let previewCameraModelID = "CIFilterCam Model"
        // https://developer.apple.com/documentation/coremediaio/creating_a_camera_extension_with_core_media_i_o
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        let devices = discoverySession.devices
        let device = devices.first(where: { $0.modelID == previewCameraModelID })!
        input = try! AVCaptureDeviceInput(device: device)
        super.init()
        cameras = devices.filter({ $0.modelID != previewCameraModelID }).map({ Camera(id: $0.uniqueID, name: $0.localizedName) })
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
