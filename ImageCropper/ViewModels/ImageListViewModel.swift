import SwiftUI
import PhotosUI
import Combine

@MainActor
class ImageListViewModel: ObservableObject {
    @Published var processedImages: [ProcessedImage] = []
    @Published var cropPercentage = CropPercentage()
    @Published var isLoading = false
    @Published var error: Error?
    
    private let imageCache = ImageCache()
    private lazy var imageProcessingService: ImageProcessingService = LocalImageProcessingService(cache: imageCache)
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupCropPercentageObserver()
        setupMemoryWarningObserver()
    }
    
    private func setupCropPercentageObserver() {
        $cropPercentage
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newPercentage in
                self?.reprocessAllImages(with: newPercentage)
            }
            .store(in: &cancellables)
    }
    
    func processSelectedImages(_ items: [PhotosPickerItem]) {
        Task {
            isLoading = true
            error = nil
            
            for item in items {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        let processedImage = ProcessedImage(originalImage: uiImage)
                        processedImages.append(processedImage)
                        await processImage(processedImage)
                    }
                } catch {
                    self.error = error
                }
            }
            
            isLoading = false
        }
    }
    
    private func processImage(_ processedImage: ProcessedImage) async {
        processedImage.setProcessing(true)
        
        let priority = processedImage.isVisible ? TaskPriority.high : TaskPriority.medium
        
        let task = Task(priority: priority) {
            do {
                let request = ImageProcessingRequest(
                    image: processedImage.originalImage,
                    cropPercentage: cropPercentage
                )
                
                let croppedImage = try await imageProcessingService.processImage(request)
                
                if !Task.isCancelled {
                    processedImage.updateCroppedImage(croppedImage)
                }
            } catch {
                if !Task.isCancelled {
                    processedImage.setError(error)
                }
            }
            
            processedImage.setProcessing(false)
        }
        
        processedImage.setProcessingTask(task)
    }
    
    func markImageVisible(_ processedImage: ProcessedImage) {
        processedImage.isVisible = true
        
        if processedImage.croppedImage == nil && !processedImage.isProcessing && processedImage.error == nil {
            Task {
                await processImage(processedImage)
            }
        }
    }
    
    func markImageInvisible(_ processedImage: ProcessedImage) {
        processedImage.isVisible = false
    }
    
    private func reprocessAllImages(with newPercentage: CropPercentage) {
        imageCache.removeAllImages()
        
        let visibleImages = processedImages.filter { $0.isVisible }
        let invisibleImages = processedImages.filter { !$0.isVisible }
        
        for image in processedImages {
            image.cancelProcessing()
        }
        
        for image in visibleImages {
            Task(priority: .high) {
                await processImage(image)
            }
        }
        
        for image in invisibleImages {
            Task(priority: .medium) {
                await processImage(image)
            }
        }
    }
    
    func removeImage(_ processedImage: ProcessedImage) {
        processedImage.cancelProcessing()
        processedImages.removeAll { $0.id == processedImage.id }
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func handleMemoryWarning() {
        imageCache.removeAllImages()
        
        for image in processedImages where !image.isProcessing {
            image.cancelProcessing()
        }
    }
}