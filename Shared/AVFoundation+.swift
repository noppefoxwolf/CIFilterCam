import AVFoundation

extension AVCaptureDevice.DiscoverySession {
    public static func extensionDevice() -> AVCaptureDevice {
        // https://developer.apple.com/documentation/coremediaio/creating_a_camera_extension_with_core_media_i_o
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        let devices = discoverySession.devices
        let device = devices.first(where: { $0.modelID == extensionCameraModelID })!
        return device
    }
    
    public static func devicesWithoutExtension() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        let devices = discoverySession.devices
        return devices.filter({ $0.modelID != extensionCameraModelID })
    }
}
