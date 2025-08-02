# ImageCropper - iOS Image Processing App

An iOS application that processes images by cropping them based on user-defined percentages. Built with SwiftUI and following modern iOS development best practices.

## Overview

ImageCropper allows users to:
- Select multiple images (up to 100) from their device gallery
- Process images with a customizable crop percentage (5-20%)
- View original and processed images side by side
- Adjust the crop percentage dynamically with reactive updates
- View images in full-screen with zoom and pan capabilities

## Architecture

### Design Patterns Used

**MVVM (Model-View-ViewModel)**
- Clean separation of concerns between UI and business logic
- `ImageListViewModel` manages state and coordinates image processing
- Reactive updates using Combine publishers

**Protocol-Oriented Design**
- `ImageProcessingService` protocol defines the service contract
- `LocalImageProcessingService` provides concrete implementation
- Enables easy testing and future service implementations

**Actor-Based Concurrency Control**
- `ProcessingActor` manages concurrent operation limits for thread safety
- `LocalImageProcessingService` uses the actor to prevent system overload
- Modern Swift concurrency with async/await and Task.detached for CPU-intensive work

### Project Structure

```
ImageCropper/
├── Models/
│   ├── CropPercentage.swift         # Type-safe crop percentage (5-20%)
│   ├── ProcessedImage.swift         # Observable image model with Hashable conformance
│   └── ImageProcessingRequest.swift # Service request model
├── Services/
│   ├── ImageProcessingService.swift    # Protocol definition
│   ├── LocalImageProcessingService.swift # Concrete implementation with caching
│   ├── ImageCache.swift               # Memory-aware NSCache implementation
│   └── ProcessingActor.swift          # Concurrency control actor
├── ViewModels/
│   └── ImageListViewModel.swift     # Main view model with priority processing
├── Views/
│   ├── ImageListView.swift          # Main interface with visibility tracking
│   ├── ImageRowView.swift           # Image pair display component
│   ├── CropSliderView.swift         # Reactive slider control
│   └── ImageDetailView.swift        # Full-screen viewer with zoom/pan gestures
├── Utils/
│   └── ImageDownsampler.swift       # Performance optimization utilities
├── ImageCropperApp.swift            # App entry point
└── ContentView.swift                # Root view
```

```
ImageCropperTests/
├── ImageCropperTests.swift                    # Core functionality tests
├── ImageCacheTests.swift                      # Cache behavior and thread safety
├── ProcessingActorTests.swift                 # Concurrency control testing
├── ImageDownsamplerTests.swift                # Image optimization tests
└── LocalImageProcessingServiceCacheTests.swift # Service integration tests
```

## Key Implementation Decisions

### 1. **Service Architecture**
- **Decision**: Designed as protocol-based service with async/await API
- **Rationale**: Mimics remote API structure while running in-process
- **Benefit**: Easy to swap implementations or add remote processing later

### 2. **Reactive State Management**
- **Decision**: Combine publishers for crop percentage changes
- **Rationale**: Automatic reprocessing when slider value changes
- **Benefit**: Smooth user experience with real-time updates

### 3. **Memory Management**
- **Decision**: Cancel previous processing tasks when crop percentage changes
- **Rationale**: Prevents unnecessary work and memory usage
- **Benefit**: Efficient resource utilization with large image sets

### 4. **Image Processing Algorithm**
- **Decision**: Core Graphics-based cropping from center
- **Rationale**: Standard iOS image manipulation approach
- **Benefit**: Predictable results with good performance

### 5. **UI Performance**
- **Decision**: LazyVStack over List for image display
- **Rationale**: Better control over image-heavy content layout
- **Benefit**: Smooth scrolling with many images

## Technical Highlights

### Performance-Optimized Image Processing Service
```swift
final class LocalImageProcessingService: ImageProcessingService {
    private let processingActor = ProcessingActor()
    private let cache: ImageCaching?
    
    func processImage(_ request: ImageProcessingRequest) async throws -> UIImage {
        // Check cache first
        if let cached = cache?.image(for: request.requestId, cropPercentage: request.cropPercentage.value) {
            return cached
        }
        
        // Limit concurrent operations
        try await processingActor.checkConcurrencyLimit()
        
        // Use cancellation handler to properly manage actor state
        return try await withTaskCancellationHandler {
            try await performProcessing(request)
        } onCancel: {
            Task { await processingActor.decrementCount() }
        }
    }
    
    private func performProcessing(_ request: ImageProcessingRequest) async throws -> UIImage {
        defer { Task { await processingActor.decrementCount() } }
        
        // Downsample large images before processing
        let downsampledImage = await Task.detached(priority: .userInitiated) {
            ImageDownsampler.downsample(request.image)
        }.value
        
        // Process image with proper error handling
        let processedImage = try await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { throw ImageProcessingError.processingFailed }
            return try self.cropImage(downsampledImage, percentage: request.cropPercentage.percentage)
        }.value
        
        // Cache result for future use
        cache?.store(processedImage, for: request.requestId, cropPercentage: request.cropPercentage.value)
        return processedImage
    }
}
```

### Memory-Aware Image Caching
```swift
final class ImageCache: ImageCaching {
    private let cache = NSCache<CacheKey, UIImage>()
    
    init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024  // 100MB
        
        // Clear cache on memory warnings
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification, object: nil
        )
    }
}
```

### Concurrency Management
```swift
actor ProcessingActor {
    private var currentOperations = 0
    private let maxOperations: Int
    
    func checkConcurrencyLimit() async throws {
        while currentOperations >= maxOperations {
            try Task.checkCancellation()
            await Task.yield()
        }
        currentOperations += 1
    }
}
```

### Visibility-Based Processing Priority
```swift
$cropPercentage
    .dropFirst()
    .removeDuplicates()
    .sink { [weak self] newPercentage in
        self?.reprocessAllImages(with: newPercentage)
    }
    .store(in: &cancellables)

func reprocessAllImages(with newPercentage: CropPercentage) {
    imageCache.removeAllImages()
    
    // Process visible images first with high priority
    let visibleImages = processedImages.filter { $0.isVisible }
    let invisibleImages = processedImages.filter { !$0.isVisible }
    
    for image in visibleImages {
        Task(priority: .high) { await processImage(image) }
    }
    
    for image in invisibleImages {
        Task(priority: .medium) { await processImage(image) }
    }
}
```

## Testing Strategy

Comprehensive unit test coverage across all components:

- **Model Validation**: CropPercentage bounds checking and type safety
- **Service Logic**: Image processing accuracy and error handling
- **Async Operations**: Proper async/await behavior and cancellation
- **Request Generation**: Unique request IDs and data integrity
- **Caching Logic**: Cache hits, misses, memory management, and thread safety
- **Concurrency Control**: Actor-based operation limiting and task coordination
- **Image Processing**: Downsampling, memory estimation, and quality preservation
- **Performance Optimization**: Visibility-based priority and cache integration

## What I Would Implement Next (In Priority Order)

### 1. **Advanced Performance Features**
- **Progressive JPEG Loading**: Stream images for smoother initial load
- **Predictive Caching**: Pre-process common crop percentages
- **Memory Pressure Handling**: Dynamic quality reduction under memory constraints
- **Background Task Support**: Continue processing when app is backgrounded

### 2. **Enhanced User Experience**
- **Batch Processing Controls**: Start/stop processing for large sets
- **Progress Indicators**: Show detailed progress for each image
- **Export Functionality**: Save processed images back to Photos library
- **Undo/Redo**: Allow users to revert processing changes

### 3. **Advanced Image Features**
- **Multiple Crop Modes**: Center crop, smart crop, custom crop areas
- **Additional Filters**: Brightness, contrast, saturation adjustments
- **Crop Previews**: Real-time preview while adjusting percentage
- **Custom Aspect Ratios**: Square, 16:9, custom ratio options

### 4. **App Architecture Improvements**
- **Dependency Injection Container**: Proper DI setup for better testability
- **Coordinator Pattern**: Navigation management for complex flows
- **Data Persistence**: Core Data for saving processing history and user preferences
- **Settings Screen**: Cache size limits, processing quality options, and export preferences

### 5. **Production Readiness**
- **Error Recovery**: Robust error handling with user-friendly messages
- **Accessibility**: VoiceOver support and accessibility identifiers
- **Localization**: Multi-language support
- **Analytics**: Usage tracking and performance monitoring

### 6. **Extended Testing**
- **UI Tests**: Critical user flows automation
- **Integration Tests**: End-to-end image processing workflows
- **Performance Tests**: Memory usage and processing speed benchmarks
- **Accessibility Tests**: Screen reader and accessibility validation

## Technical Trade-offs Made

### Performance vs. Simplicity
- **Chosen**: UIImage-based processing over lower-level Core Image
- **Trade-off**: Slightly less performance but much clearer, maintainable code
- **Justification**: For the assignment scope, clarity trumps micro-optimizations
- **Resolution**: Added downsampling and caching to mitigate performance concerns

### Memory vs. Features
- **Chosen**: Comprehensive memory management with caching and downsampling
- **Trade-off**: Additional complexity in cache management and memory monitoring
- **Benefit**: Can handle 100+ high-resolution images without memory issues

### Testing Coverage vs. Time
- **Chosen**: Comprehensive unit testing across all components
- **Trade-off**: More test files to maintain but higher confidence in reliability
- **Justification**: Had extra time within the 4 hour limit


## Building and Running

1. Open `ImageCropper.xcodeproj` in Xcode 15.0+
2. Select iOS 17.6+ simulator or device
3. Build and run (`Cmd+R`)
4. Grant photo library permissions when prompted
5. Tap "Select Images" to start processing images

## Testing

Run unit tests: `Cmd+U` or use Xcode's Test Navigator

## Additional Implementation Notes

### Performance Improvements Implemented
- **Image Caching**: NSCache-based system with memory pressure handling
- **Concurrency Control**: Actor-based limiting to prevent system overload  
- **Image Downsampling**: Automatic resizing of large images before processing
- **Visibility-Based Priority**: High priority for visible images, medium for off-screen
- **Memory Management**: Automatic cache clearing on memory warnings

### Test Coverage Added
- **ImageCacheTests**: Cache behavior, thread safety, memory management
- **ProcessingActorTests**: Concurrency limits, cancellation, task coordination
- **ImageDownsamplerTests**: Size reduction, aspect ratio preservation, memory estimation
- **LocalImageProcessingServiceCacheTests**: Cache integration, concurrent processing

### UI/UX Enhancements Implemented
- **Advanced Gesture Support**: Pinch-to-zoom (0.5x-5x scale), pan with boundary constraints
- **Interactive Animations**: Spring-based zoom transitions, smooth gesture feedback
- **Image Toggle**: Switch between original and processed views with animation
- **Double-Tap Zoom**: Quick zoom in/out functionality
- **Boundary Management**: Prevents panning beyond image bounds when zoomed