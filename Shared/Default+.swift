import Defaults
import Foundation

public let extensionBundleID: String = "dev.noppe.CIFilterCam.Extension"
public let extensionCameraModelID: String = "CIFilterCam Model"
public let noneDeviceID: String = "dev.noppe.none"

public let extensionDefaults = UserDefaults(suiteName: "FBQ6Z8AF3U.dev.noppe.CIFilterCam")!

extension Defaults.Keys {
    public static let isBypass = Key<Bool>("isBypass", default: false, suite: extensionDefaults)
    public static let deviceID = Key<String>("deviceID", default: noneDeviceID, suite: extensionDefaults)
    public static let filter = Key<Filter>("filter", default: .sepiaTone, suite: extensionDefaults)
}
