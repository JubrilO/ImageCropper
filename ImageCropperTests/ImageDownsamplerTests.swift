import XCTest
@testable import ImageCropper

final class ImageDownsamplerTests: XCTestCase {
    
    func testDownsampleLargeImage() {
        let largeImage = createTestImage(size: CGSize(width: 2000, height: 2000))
        let downsampledImage = ImageDownsampler.downsample(largeImage)
        
        XCTAssertLessThanOrEqual(downsampledImage.size.width, 1024)
        XCTAssertLessThanOrEqual(downsampledImage.size.height, 1024)
        
        // Verify aspect ratio is maintained
        let originalAspectRatio = largeImage.size.width / largeImage.size.height
        let downsampledAspectRatio = downsampledImage.size.width / downsampledImage.size.height
        XCTAssertEqual(originalAspectRatio, downsampledAspectRatio, accuracy: 0.01)
    }
    
    func testDownsampleSmallImageUnchanged() {
        let smallImage = createTestImage(size: CGSize(width: 500, height: 300))
        let result = ImageDownsampler.downsample(smallImage)
        
        XCTAssertEqual(result.size, smallImage.size)
    }
    
    func testDownsampleWithCustomMaxDimension() {
        let image = createTestImage(size: CGSize(width: 800, height: 600))
        let downsampledImage = ImageDownsampler.downsample(image, to: 400)
        
        XCTAssertLessThanOrEqual(downsampledImage.size.width, 400)
        XCTAssertLessThanOrEqual(downsampledImage.size.height, 400)
        
        // Verify largest dimension is scaled to target
        let maxDimension = max(downsampledImage.size.width, downsampledImage.size.height)
        XCTAssertEqual(maxDimension, 400, accuracy: 1.0)
    }
    
    func testDownsampleForDisplayLargeImage() {
        let largeImage = createTestImage(size: CGSize(width: 3000, height: 2000))
        let targetSize = CGSize(width: 300, height: 200)
        let displayImage = ImageDownsampler.downsampleForDisplay(largeImage, targetSize: targetSize)
        
        // Should be scaled to fit target size (maintaining aspect ratio)
        XCTAssertGreaterThanOrEqual(displayImage.size.width, targetSize.width)
        XCTAssertGreaterThanOrEqual(displayImage.size.height, targetSize.height)
        
        // One dimension should match the target
        let widthMatches = abs(displayImage.size.width - targetSize.width) < 1.0
        let heightMatches = abs(displayImage.size.height - targetSize.height) < 1.0
        XCTAssertTrue(widthMatches || heightMatches)
    }
    
    func testDownsampleForDisplaySmallImage() {
        let smallImage = createTestImage(size: CGSize(width: 100, height: 50))
        let targetSize = CGSize(width: 300, height: 200)
        let result = ImageDownsampler.downsampleForDisplay(smallImage, targetSize: targetSize)
        
        // Small image should remain unchanged
        XCTAssertEqual(result.size, smallImage.size)
    }
    
    func testEstimatedMemoryUsage() {
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        let estimatedUsage = ImageDownsampler.estimatedMemoryUsage(for: image)
        
        // For a 100x100 image at scale 1.0, should be roughly 100 * 100 * 4 = 40,000 bytes
        let expectedUsage = Int(100 * 100 * 4)
        XCTAssertEqual(estimatedUsage, expectedUsage)
    }
    
    func testEstimatedMemoryUsageWithScale() {
        // Create an image with scale factor
        let size = CGSize(width: 100, height: 100)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let scaledImage = renderer.image { context in
            UIColor.blue.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
        
        let estimatedUsage = ImageDownsampler.estimatedMemoryUsage(for: scaledImage)
        
        // Should account for the scale factor: 100 * 2 * 100 * 2 * 4 = 160,000 bytes
        let expectedUsage = Int(100 * 2 * 100 * 2 * 4)
        XCTAssertEqual(estimatedUsage, expectedUsage)
    }
    
    func testDownsamplePreservesImageQuality() {
        let originalImage = createTestImage(size: CGSize(width: 2000, height: 1000))
        let downsampledImage = ImageDownsampler.downsample(originalImage)
        
        // Verify the downsampled image is valid
        XCTAssertNotNil(downsampledImage.cgImage)
        XCTAssertGreaterThan(downsampledImage.size.width, 0)
        XCTAssertGreaterThan(downsampledImage.size.height, 0)
    }
    
    func testDownsampleMaintainsPortraitOrientation() {
        let portraitImage = createTestImage(size: CGSize(width: 1000, height: 2000))
        let downsampledImage = ImageDownsampler.downsample(portraitImage)
        
        XCTAssertGreaterThan(downsampledImage.size.height, downsampledImage.size.width)
        XCTAssertEqual(downsampledImage.size.height, 1024)
    }
    
    func testDownsampleMaintainsLandscapeOrientation() {
        let landscapeImage = createTestImage(size: CGSize(width: 2000, height: 1000))
        let downsampledImage = ImageDownsampler.downsample(landscapeImage)
        
        XCTAssertGreaterThan(downsampledImage.size.width, downsampledImage.size.height)
        XCTAssertEqual(downsampledImage.size.width, 1024)
    }
    
    private func createTestImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.green.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
    }
}