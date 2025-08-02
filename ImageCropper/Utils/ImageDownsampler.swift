import UIKit
import CoreGraphics

enum ImageDownsampler {
    static let maxProcessingDimension: CGFloat = 1024
    
    static func downsample(_ image: UIImage, to maxDimension: CGFloat = maxProcessingDimension) -> UIImage {
        let size = image.size
        
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    static func downsampleForDisplay(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        guard size.width > targetSize.width || size.height > targetSize.height else {
            return image
        }
        
        let widthScale = targetSize.width / size.width
        let heightScale = targetSize.height / size.height
        let scale = max(widthScale, heightScale)
        
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    static func estimatedMemoryUsage(for image: UIImage) -> Int {
        let pixelCount = Int(image.size.width * image.scale * image.size.height * image.scale)
        return pixelCount * 4
    }
}