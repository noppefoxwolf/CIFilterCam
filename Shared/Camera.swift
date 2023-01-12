
public struct Camera: Identifiable {
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    public var id: String
    public var name: String
}

extension Camera {
    public static var none: Camera = Camera(id: noneDeviceID, name: "-------")
}
