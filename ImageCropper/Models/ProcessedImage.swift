import SwiftUI
import Combine

@MainActor
class ProcessedImage: ObservableObject, Identifiable {
    let id = UUID()
    let originalImage: UIImage
    
    @Published private(set) var croppedImage: UIImage?
    @Published private(set) var isProcessing = false
    @Published private(set) var error: Error?
    
    private var processingTask: Task<Void, Never>?
    
    init(originalImage: UIImage) {
        self.originalImage = originalImage
    }
    
    func updateCroppedImage(_ image: UIImage) {
        self.croppedImage = image
    }
    
    func setProcessing(_ processing: Bool) {
        self.isProcessing = processing
    }
    
    func setError(_ error: Error?) {
        self.error = error
    }
    
    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
    }
    
    func setProcessingTask(_ task: Task<Void, Never>) {
        processingTask = task
    }
}