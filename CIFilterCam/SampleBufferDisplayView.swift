import AppKit
import AVFoundation
import SwiftUI

struct SampleBufferDisplayView: NSViewRepresentable {
    let sampleBuffer: CMSampleBuffer?
    
    func makeNSView(context: Context) -> AVSampleBufferDisplayView {
        AVSampleBufferDisplayView(frame: .null)
    }
    
    func updateNSView(_ nsView: AVSampleBufferDisplayView, context: Context) {
        if let sampleBuffer = sampleBuffer {
            nsView.sampleBufferDisplayLayer.enqueue(sampleBuffer)
        }
    }
}

class AVSampleBufferDisplayView: NSView {
    let sampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer = sampleBufferDisplayLayer
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
