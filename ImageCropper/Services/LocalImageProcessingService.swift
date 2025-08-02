import UIKit
import CoreGraphics

actor LocalImageProcessingService: ImageProcessingService {
    private let processingQueue = DispatchQueue(label: "com.imagecropper.processing", qos: .userInitiated)
    
    func processImage(_ request: ImageProcessingRequest) async throws -> UIImage {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        try Task.checkCancellation()
        
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    let croppedImage = try self.cropImage(request.image, percentage: request.cropPercentage.percentage)
                    continuation.resume(returning: croppedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func cropImage(_ image: UIImage, percentage: Double) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let cropAmount = percentage
        let cropWidth = width * CGFloat(cropAmount)
        let cropHeight = height * CGFloat(cropAmount)
        
        let newWidth = width - (cropWidth * 2)
        let newHeight = height - (cropHeight * 2)
        
        guard newWidth > 0 && newHeight > 0 else {
            throw ImageProcessingError.processingFailed
        }
        
        let cropRect = CGRect(
            x: cropWidth,
            y: cropHeight,
            width: newWidth,
            height: newHeight
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            throw ImageProcessingError.processingFailed
        }
        
        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
        
        return croppedImage
    }
}