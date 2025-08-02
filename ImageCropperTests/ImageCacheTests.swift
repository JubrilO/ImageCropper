import XCTest
@testable import ImageCropper

final class ImageCacheTests: XCTestCase {
    var cache: ImageCache!
    
    override func setUp() {
        super.setUp()
        cache = ImageCache()
    }
    
    override func tearDown() {
        cache = nil
        super.tearDown()
    }
    
    func testStoreAndRetrieveImage() {
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        let imageId = UUID()
        let cropPercentage = 10.0
        
        cache.store(image, for: imageId, cropPercentage: cropPercentage)
        
        let retrievedImage = cache.image(for: imageId, cropPercentage: cropPercentage)
        XCTAssertNotNil(retrievedImage)
        XCTAssertEqual(retrievedImage?.size, image.size)
    }
    
    func testRetrieveNonExistentImage() {
        let imageId = UUID()
        let cropPercentage = 10.0
        
        let retrievedImage = cache.image(for: imageId, cropPercentage: cropPercentage)
        XCTAssertNil(retrievedImage)
    }
    
    func testDifferentCropPercentagesStoredSeparately() {
        let image1 = createTestImage(size: CGSize(width: 100, height: 100))
        let image2 = createTestImage(size: CGSize(width: 200, height: 200))
        let imageId = UUID()
        
        cache.store(image1, for: imageId, cropPercentage: 10.0)
        cache.store(image2, for: imageId, cropPercentage: 15.0)
        
        let retrieved1 = cache.image(for: imageId, cropPercentage: 10.0)
        let retrieved2 = cache.image(for: imageId, cropPercentage: 15.0)
        
        XCTAssertNotNil(retrieved1)
        XCTAssertNotNil(retrieved2)
        XCTAssertEqual(retrieved1?.size, image1.size)
        XCTAssertEqual(retrieved2?.size, image2.size)
    }
    
    func testRemoveSpecificImage() {
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        let imageId = UUID()
        let cropPercentage = 10.0
        
        cache.store(image, for: imageId, cropPercentage: cropPercentage)
        XCTAssertNotNil(cache.image(for: imageId, cropPercentage: cropPercentage))
        
        cache.removeImage(for: imageId, cropPercentage: cropPercentage)
        XCTAssertNil(cache.image(for: imageId, cropPercentage: cropPercentage))
    }
    
    func testRemoveAllImages() {
        let imageId1 = UUID()
        let imageId2 = UUID()
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        
        cache.store(image, for: imageId1, cropPercentage: 10.0)
        cache.store(image, for: imageId2, cropPercentage: 15.0)
        
        cache.removeAllImages()
        
        XCTAssertNil(cache.image(for: imageId1, cropPercentage: 10.0))
        XCTAssertNil(cache.image(for: imageId2, cropPercentage: 15.0))
    }
    
    func testThreadSafety() {
        let expectation = XCTestExpectation(description: "Concurrent access")
        let iterations = 100
        let group = DispatchGroup()
        
        for i in 0..<iterations {
            group.enter()
            DispatchQueue.global().async {
                let imageId = UUID()
                let image = self.createTestImage(size: CGSize(width: 50, height: 50))
                let cropPercentage = Double(i % 20) + 5.0
                
                self.cache.store(image, for: imageId, cropPercentage: cropPercentage)
                _ = self.cache.image(for: imageId, cropPercentage: cropPercentage)
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    private func createTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}