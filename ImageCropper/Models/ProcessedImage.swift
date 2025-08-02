import SwiftUI
import Combine

@MainActor
class ProcessedImage: ObservableObject, Identifiable, Hashable {
    let id = UUID()
    let originalImage: UIImage
    
    @Published private(set) var croppedImage: UIImage?
    @Published private(set) var isProcessing = false
    @Published private(set) var error: Error?
    @Published var isVisible = false
    
    private var processingTask: Task<Void, Never>?
    
    init(originalImage: UIImage) {
        self.originalImage = originalImage
    }
    
    static func == (lhs: ProcessedImage, rhs: ProcessedImage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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