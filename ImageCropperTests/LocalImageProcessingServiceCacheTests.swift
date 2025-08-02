import XCTest
@testable import ImageCropper

final class LocalImageProcessingServiceCacheTests: XCTestCase {
    var service: LocalImageProcessingService!
    var mockCache: MockImageCache!
    
    override func setUp() {
        super.setUp()
        mockCache = MockImageCache()
        service = LocalImageProcessingService(cache: mockCache)
    }
    
    override func tearDown() {
        service = nil
        mockCache = nil
        super.tearDown()
    }
    
    func testProcessImageUsesCache() async throws {
        let originalImage = createTestImage(size: CGSize(width: 100, height: 100))
        let cachedImage = createTestImage(size: CGSize(width: 80, height: 80))
        let request = ImageProcessingRequest(
            image: originalImage,
            cropPercentage: CropPercentage(value: 10.0)
        )
        
        // Set up cache to return the cached image
        mockCache.imageToReturn = cachedImage
        
        let result = try await service.processImage(request)
        
        XCTAssertEqual(result.size, cachedImage.size)
        XCTAssertTrue(mockCache.imageCalled)
        XCTAssertFalse(mockCache.storeCalled) // Shouldn't store if already cached
    }
    
    func testProcessImageStoresInCache() async throws {
        let originalImage = createTestImage(size: CGSize(width: 100, height: 100))
        let request = ImageProcessingRequest(
            image: originalImage,
            cropPercentage: CropPercentage(value: 10.0)
        )
        
        // Cache returns nil (not cached)
        mockCache.imageToReturn = nil
        
        let result = try await service.processImage(request)
        
        XCTAssertNotNil(result)
        XCTAssertTrue(mockCache.imageCalled)
        XCTAssertTrue(mockCache.storeCalled)
        XCTAssertEqual(mockCache.storedCropPercentage, 10.0)
        XCTAssertEqual(mockCache.storedImageId, request.requestId)
    }
    
    func testProcessImageWithNilCache() async throws {
        // Test without cache
        let serviceWithoutCache = LocalImageProcessingService(cache: nil)
        let originalImage = createTestImage(size: CGSize(width: 100, height: 100))
        let request = ImageProcessingRequest(
            image: originalImage,
            cropPercentage: CropPercentage(value: 15.0)
        )
        
        let result = try await serviceWithoutCache.processImage(request)
        
        XCTAssertNotNil(result)
        // Should still process successfully without cache
        XCTAssertLessThan(result.size.width, originalImage.size.width)
        XCTAssertLessThan(result.size.height, originalImage.size.height)
    }
    
    func testConcurrentProcessingWithCache() async throws {
        let originalImage = createTestImage(size: CGSize(width: 200, height: 200))
        let iterations = 10
        
        try await withThrowingTaskGroup(of: UIImage.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    let request = ImageProcessingRequest(
                        image: originalImage,
                        cropPercentage: CropPercentage(value: Double(i % 15) + 5.0)
                    )
                    return try await self.service.processImage(request)
                }
            }
            
            var results: [UIImage] = []
            for try await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, iterations)
        }
        
        // Cache should have been accessed multiple times
        XCTAssertTrue(mockCache.imageCalled)
    }
    
    private func createTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

// MARK: - Mock Implementation

class MockImageCache: ImageCaching {
    var imageToReturn: UIImage?
    var imageCalled = false
    var storeCalled = false
    var storedImageId: UUID?
    var storedCropPercentage: Double?
    
    func image(for imageId: UUID, cropPercentage: Double) -> UIImage? {
        imageCalled = true
        return imageToReturn
    }
    
    func store(_ image: UIImage, for imageId: UUID, cropPercentage: Double) {
        storeCalled = true
        storedImageId = imageId
        storedCropPercentage = cropPercentage
    }
    
    func removeImage(for imageId: UUID, cropPercentage: Double) {
        // Implementation not needed for current tests
    }
    
    func removeAllImages() {
        // Implementation not needed for current tests
    }
}