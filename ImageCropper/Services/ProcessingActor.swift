import Foundation

actor ProcessingActor {
    private var currentOperations = 0
    private let maxOperations: Int
    
    init(maxOperations: Int = min(ProcessInfo.processInfo.activeProcessorCount, 4)) {
        self.maxOperations = maxOperations
    }
    
    func checkConcurrencyLimit() async throws {
        while currentOperations >= maxOperations {
            try Task.checkCancellation()
            await Task.yield()
        }
        currentOperations += 1
    }
    
    func decrementCount() {
        currentOperations = max(0, currentOperations - 1)
    }
    
    var activeOperations: Int {
        currentOperations
    }
}