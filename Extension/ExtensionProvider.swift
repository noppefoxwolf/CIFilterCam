//
//  ExtensionProvider.swift
//  Extension
//
//  Created by noppe on 2023/01/12.
//

import Foundation
import CoreMediaIO
import IOKit.audio
import os.log
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation
import Shared
import Defaults

let kFrameRate: Int = 60

// MARK: -

class ExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
    
    private(set) var device: CMIOExtensionDevice!
    
    private var _streamSource: ExtensionStreamSource!
    
    private var _videoDescription: CMFormatDescription!
    
    private var _bufferPool: CVPixelBufferPool!
    
    var filter: Filter = .sepiaTone
    
    let ciContext = CIContext()
    
    var isBypass: Bool = true
    
    var input: AVCaptureDeviceInput? = nil {
        didSet {
            session.beginConfiguration()
            if let oldValue = oldValue {
                session.removeInput(oldValue)
            }
            if let newValue = input {
                session.addInput(newValue)
            }
            session.commitConfiguration()
        }
    }
    
    func findCaptureDevice(by id: String) -> AVCaptureDeviceInput? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown, .deskViewCamera, .builtInMicrophone],
            mediaType: .video,
            position: .unspecified
        )
        let devices = discoverySession.devices
        guard let device = devices.first(where: { $0.uniqueID == id }) else { return nil }
        return try? AVCaptureDeviceInput(device: device)
    }
    
    lazy var output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: .main)
        session.beginConfiguration()
        session.addOutput(output)
        session.commitConfiguration()
        return output
    }()
    
    let session: AVCaptureSession = AVCaptureSession()
	
	init(localizedName: String) {
        
		super.init()
		let deviceID = UUID() // replace this with your device UUID
		self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
		
		let dims = CMVideoDimensions(width: 1920, height: 1080)
		CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType: kCVPixelFormatType_32BGRA, width: dims.width, height: dims.height, extensions: nil, formatDescriptionOut: &_videoDescription)
		
		let pixelBufferAttributes: NSDictionary = [
			kCVPixelBufferWidthKey: dims.width,
			kCVPixelBufferHeightKey: dims.height,
			kCVPixelBufferPixelFormatTypeKey: _videoDescription.mediaSubType,
			kCVPixelBufferIOSurfacePropertiesKey: [:]
		]
		CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &_bufferPool)
		
		let videoStreamFormat = CMIOExtensionStreamFormat.init(formatDescription: _videoDescription, maxFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), minFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), validFrameDurations: nil)
		
		let videoID = UUID() // replace this with your video UUID
		_streamSource = ExtensionStreamSource(localizedName: "CIFilterCam.Video", streamID: videoID, streamFormat: videoStreamFormat, device: device)
		do {
			try device.addStream(_streamSource.stream)
		} catch let error {
			fatalError("Failed to add stream: \(error.localizedDescription)")
		}
        
        _ = output
        observeSettings()
	}
    
    func observeSettings() {
        Task {
            for await isBypass in Defaults.updates(.isBypass) {
                self.isBypass = isBypass
            }
        }
        Task {
            for await uniqID in Defaults.updates(.deviceID) {
                if let deviceInput = findCaptureDevice(by: uniqID) {
                    self.input = deviceInput
                }
            }
        }
        Task {
            for await filter in Defaults.updates(.filter) {
                self.filter = filter
            }
        }
    }
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.deviceTransportType, .deviceModel]
	}
	
	func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
		
		let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
		if properties.contains(.deviceTransportType) {
			deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
		}
		if properties.contains(.deviceModel) {
			deviceProperties.model = extensionCameraModelID
		}
		
		return deviceProperties
	}
	
	func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
		
		// Handle settable properties here.
	}
	
	func startStreaming() {
        session.startRunning()
	}
	
	func stopStreaming() {
        session.stopRunning()
	}
}

extension ExtensionDeviceSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isBypass {
            _streamSource.stream.send(sampleBuffer, discontinuity: .time, hostTimeInNanoseconds: 0)
            return
        }
        
        let imageBuffer = sampleBuffer.imageBuffer!
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        }

        var pixelBufferOut: CVPixelBuffer? = nil
        let cvReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _bufferPool, &pixelBufferOut)
        if cvReturn == kCVReturnError {
            fatalError()
        }

        var status: OSStatus = 0
        
        var timingInfoOut = CMSampleTimingInfo()
        timingInfoOut.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())

        var formatDesc: CMFormatDescription?
        status = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBufferOut!,
                                                     formatDescriptionOut: &formatDesc)
        if status != 0 {
            fatalError()
        }

        var sampleBufferOut: CMSampleBuffer?
        status = CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                              imageBuffer: pixelBufferOut!,
                                                              formatDescription: formatDesc!,
                                                              sampleTiming: &timingInfoOut,
                                                              sampleBufferOut: &sampleBufferOut)
        if status != 0 {
            fatalError()
        }
        
        let inputImage = CIImage(cvImageBuffer: imageBuffer)
        if let outputImage = filter.apply(to: inputImage) {
            ciContext.render(outputImage, to: pixelBufferOut!)
        }
        
        let hostTimeInNanoseconds = UInt64(timingInfoOut.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
        _streamSource.stream.send(sampleBufferOut!, discontinuity: [], hostTimeInNanoseconds: hostTimeInNanoseconds)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        _streamSource.stream.send(sampleBuffer, discontinuity: .sampleDropped, hostTimeInNanoseconds: 0)
    }
}

// MARK: -

class ExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
	
	private(set) var stream: CMIOExtensionStream!
	
	let device: CMIOExtensionDevice
	
	private let _streamFormat: CMIOExtensionStreamFormat
	
	init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {
		
		self.device = device
		self._streamFormat = streamFormat
		super.init()
		self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: self)
	}
	
	var formats: [CMIOExtensionStreamFormat] {
		
		return [_streamFormat]
	}
	
	var activeFormatIndex: Int = 0 {
		
		didSet {
			if activeFormatIndex >= 1 {
				os_log(.error, "Invalid index")
			}
		}
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.streamActiveFormatIndex, .streamFrameDuration]
	}
	
	func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
		
		let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
		if properties.contains(.streamActiveFormatIndex) {
			streamProperties.activeFormatIndex = 0
		}
		if properties.contains(.streamFrameDuration) {
			let frameDuration = CMTime(value: 1, timescale: Int32(kFrameRate))
			streamProperties.frameDuration = frameDuration
		}
		
		return streamProperties
	}
	
	func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
		
		if let activeFormatIndex = streamProperties.activeFormatIndex {
			self.activeFormatIndex = activeFormatIndex
		}
	}
	
	func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
		
		// An opportunity to inspect the client info and decide if it should be allowed to start the stream.
		return true
	}
	
	func startStream() throws {
		
		guard let deviceSource = device.source as? ExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.startStreaming()
	}
	
	func stopStream() throws {
		
		guard let deviceSource = device.source as? ExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.stopStreaming()
	}
}

// MARK: -

class ExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
	
	private(set) var provider: CMIOExtensionProvider!
	
	private var deviceSource: ExtensionDeviceSource!
	
	// CMIOExtensionProviderSource protocol methods (all are required)
	
	init(clientQueue: DispatchQueue?) {
		
		super.init()
		
		provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
		deviceSource = ExtensionDeviceSource(localizedName: "CIFilterCam (Swift)")
		
		do {
			try provider.addDevice(deviceSource.device)
		} catch let error {
			fatalError("Failed to add device: \(error.localizedDescription)")
		}
	}
	
	func connect(to client: CMIOExtensionClient) throws {
		
		// Handle client connect
	}
	
	func disconnect(from client: CMIOExtensionClient) {
		
		// Handle client disconnect
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		// See full list of CMIOExtensionProperty choices in CMIOExtensionProperties.h
		return [.providerManufacturer]
	}
	
	func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
		
		let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
		if properties.contains(.providerManufacturer) {
			providerProperties.manufacturer = "CIFilterCam Manufacturer"
		}
		return providerProperties
	}
	
	func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
		
		// Handle settable properties here.
	}
}
