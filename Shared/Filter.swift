import CoreImage
import CoreImage.CIFilterBuiltins
import Defaults

public enum Filter: String, Defaults.Serializable, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case colorMatrix = "Color Matrix"
    case photoEffectChrome = "Photo Effect Chrome"
    case photoEffectInstant = "Photo Effect Instant"
    case photoEffectNoir = "Photo Effect Noir"
    case sepiaTone = "Sepia Tone"
    case vignetteEffect = "Vignette Effect"
    case bumpDistortion = "Bump Distortion"
    case twirlDistortion = "Twirl Distortion"
    
    public func apply(to inputImage: CIImage) -> CIImage? {
        switch self {
        case .colorMatrix:
            let filter = CIFilter.colorMatrix()
            filter.inputImage = inputImage
            return filter.outputImage
        case .photoEffectChrome:
            let filter = CIFilter.photoEffectChrome()
            filter.inputImage = inputImage
            return filter.outputImage
        case .photoEffectInstant:
            let filter = CIFilter.photoEffectInstant()
            filter.inputImage = inputImage
            return filter.outputImage
        case .photoEffectNoir:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = inputImage
            return filter.outputImage
        case .sepiaTone:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = inputImage
            return filter.outputImage
        case .vignetteEffect:
            let filter = CIFilter.vignetteEffect()
            filter.inputImage = inputImage
            return filter.outputImage
        case .bumpDistortion:
            let filter = CIFilter.bumpDistortion()
            filter.inputImage = inputImage
            return filter.outputImage
        case .twirlDistortion:
            let filter = CIFilter.twirlDistortion()
            filter.inputImage = inputImage
            return filter.outputImage
        }
    }
}
