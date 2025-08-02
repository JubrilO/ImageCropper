import XCTest
@testable import ImageCropper

final class ImageCropperTests: XCTestCase {
    var imageProcessingService: LocalImageProcessingService!
    var testImage: UIImage!
    
    override func setUpWithError() throws {
        imageProcessingService = LocalImageProcessingService()
        
        let size = CGSize(width: 100, height: 100)
        testImage = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    override func tearDownWithError() throws {
        imageProcessingService = nil
        testImage = nil
    }
    
    func testCropPercentageValidation() throws {
        var cropPercentage = CropPercentage(value: 3.0)
        XCTAssertEqual(cropPercentage.value, 5.0, "Crop percentage should clamp to minimum")
        
        cropPercentage = CropPercentage(value: 25.0)
        XCTAssertEqual(cropPercentage.value, 20.0, "Crop percentage should clamp to maximum")
        
        cropPercentage = CropPercentage(value: 10.0)
        XCTAssertEqual(cropPercentage.value, 10.0, "Valid crop percentage should be preserved")
    }
    
    func testCropPercentageUpdate() throws {
        var cropPercentage = CropPercentage()
        
        cropPercentage.update(15.0)
        XCTAssertEqual(cropPercentage.value, 15.0, "Update should change the value")
        
        cropPercentage.update(30.0)
        XCTAssertEqual(cropPercentage.value, 20.0, "Update should clamp to maximum")
    }
    
    func testImageProcessingSuccess() async throws {
        let cropPercentage = CropPercentage(value: 10.0)
        let request = ImageProcessingRequest(image: testImage, cropPercentage: cropPercentage)
        
        let processedImage = try await imageProcessingService.processImage(request)
        
        XCTAssertNotNil(processedImage, "Processed image should not be nil")
        XCTAssertLessThan(processedImage.size.width, testImage.size.width, "Processed image should be smaller")
        XCTAssertLessThan(processedImage.size.height, testImage.size.height, "Processed image should be smaller")
        
        let expectedWidth = testImage.size.width * (1 - 2 * cropPercentage.percentage)
        let expectedHeight = testImage.size.height * (1 - 2 * cropPercentage.percentage)
        
        XCTAssertEqual(processedImage.size.width, expectedWidth, accuracy: 1.0, "Width should match expected crop")
        XCTAssertEqual(processedImage.size.height, expectedHeight, accuracy: 1.0, "Height should match expected crop")
    }
    
    func testImageProcessingRequestGeneration() throws {
        let cropPercentage = CropPercentage(value: 15.0)
        let request1 = ImageProcessingRequest(image: testImage, cropPercentage: cropPercentage)
        let request2 = ImageProcessingRequest(image: testImage, cropPercentage: cropPercentage)
        
        XCTAssertNotEqual(request1.requestId, request2.requestId, "Each request should have unique ID")
        XCTAssertEqual(request1.cropPercentage.value, 15.0, "Request should preserve crop percentage")
    }
    
    @MainActor
    func testProcessedImageModel() throws {
        let processedImage = ProcessedImage(originalImage: testImage)
        
        XCTAssertNotNil(processedImage.id, "ProcessedImage should have an ID")
        XCTAssertEqual(processedImage.originalImage, testImage, "Original image should be preserved")
        XCTAssertNil(processedImage.croppedImage, "Cropped image should initially be nil")
        XCTAssertFalse(processedImage.isProcessing, "Should not be processing initially")
        XCTAssertNil(processedImage.error, "Should not have error initially")
    }
}