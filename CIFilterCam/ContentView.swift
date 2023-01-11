//
//  ContentView.swift
//  CIFilterCam
//
//  Created by noppe on 2023/01/12.
//

import SwiftUI
import SystemExtensions

struct ContentView: View {
    @StateObject var installer: Installer = Installer()
    @State var isPresented: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    installer.install()
                } label: {
                    Text("Install Extension")
                }
                Button {
                    installer.uninstall()
                } label: {
                    Text("Uninstall Extension")
                }
            }
            
            Text(installer.message)
            
            Button {
                isPresented.toggle()
            } label: {
                Text("Show camera control")
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $isPresented) {
            ControllView()
                .frame(width: 640, height: 480)
        }
    }
}

class Installer: NSObject, ObservableObject {
    @Published var message: String = "Log Text"
    
    func install() {
        let extensionIdentifier = "dev.noppe.CIFilterCam.Extension"
        let activationRequest = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }
    
    func uninstall() {
        let extensionIdentifier = "dev.noppe.CIFilterCam.Extension"
        let activationRequest = OSSystemExtensionRequest.deactivationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }
}

extension Installer: OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("Approval")
        message = #function
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        print(result)
        message = "\(result)"
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        print(error)
        
        message = error.localizedDescription
    }
}
