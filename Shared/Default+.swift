import Defaults
import Foundation

public let extensionCameraModelID: String = "CIFilterCam Model"

public let extensionDefaults = UserDefaults(suiteName: "FBQ6Z8AF3U.dev.noppe.CIFilterCam")!

extension Defaults.Keys {
    public static let isBypass = Key<Bool>("isBypass", default: false, suite: extensionDefaults)
}
