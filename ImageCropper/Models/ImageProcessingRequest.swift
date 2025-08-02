import UIKit

struct ImageProcessingRequest {
    let image: UIImage
    let cropPercentage: CropPercentage
    let requestId: UUID
    
    init(image: UIImage, cropPercentage: CropPercentage) {
        self.image = image
        self.cropPercentage = cropPercentage
        self.requestId = UUID()
    }
}