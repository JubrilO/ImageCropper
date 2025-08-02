import UIKit
import CoreGraphics

final class LocalImageProcessingService: ImageProcessingService {
    private let processingQueue = DispatchQueue(label: "com.imagecropper.processing", qos: .userInitiated)
    private let concurrentQueue = DispatchQueue(label: "com.imagecropper.concurrent", qos: .userInitiated, attributes: .concurrent)
    
    private let processingActor = ProcessingActor()
    private let cache: ImageCaching?
    
    init(cache: ImageCaching? = nil) {
        self.cache = cache
    }
    
    func processImage(_ request: ImageProcessingRequest) async throws -> UIImage {
        if let cached = cache?.image(for: request.requestId, cropPercentage: request.cropPercentage.value) {
            return cached
        }
        try await processingActor.checkConcurrencyLimit()
        
        return try await withTaskCancellationHandler {
            try await performProcessing(request)
        } onCancel: {
            Task {
                await processingActor.decrementCount()
            }
        }
    }
    
    private func performProcessing(_ request: ImageProcessingRequest) async throws -> UIImage {
        defer {
            Task {
                await processingActor.decrementCount()
            }
        }
        
        //try await Task.sleep(nanoseconds: 200_000_000)
        
        try Task.checkCancellation()
        
        let downsampledImage = await Task.detached(priority: .userInitiated) {
            ImageDownsampler.downsample(request.image)
        }.value
        
        try Task.checkCancellation()
        
        let cropPercentage = request.cropPercentage.percentage
        let processedImage = try await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                throw ImageProcessingError.processingFailed
            }
            return try self.cropImage(downsampledImage, percentage: cropPercentage)
        }.value
        
        cache?.store(processedImage, for: request.requestId, cropPercentage: request.cropPercentage.value)
        
        return processedImage
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