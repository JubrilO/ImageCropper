import UIKit

enum ImageProcessingError: LocalizedError {
    case invalidImage
    case processingFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed:
            return "Failed to process image"
        case .cancelled:
            return "Processing was cancelled"
        }
    }
}

protocol ImageProcessingService {
    func processImage(_ request: ImageProcessingRequest) async throws -> UIImage
}