import SwiftUI
import PhotosUI
import Combine

@MainActor
class ImageListViewModel: ObservableObject {
    @Published var processedImages: [ProcessedImage] = []
    @Published var cropPercentage = CropPercentage()
    @Published var isLoading = false
    @Published var error: Error?
    
    private let imageProcessingService: ImageProcessingService
    private var cancellables = Set<AnyCancellable>()
    
    init(imageProcessingService: ImageProcessingService = LocalImageProcessingService()) {
        self.imageProcessingService = imageProcessingService
        setupCropPercentageObserver()
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
        
        let task = Task {
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
    
    private func reprocessAllImages(with newPercentage: CropPercentage) {
        for image in processedImages {
            image.cancelProcessing()
            Task {
                await processImage(image)
            }
        }
    }
    
    func removeImage(_ processedImage: ProcessedImage) {
        processedImage.cancelProcessing()
        processedImages.removeAll { $0.id == processedImage.id }
    }
}