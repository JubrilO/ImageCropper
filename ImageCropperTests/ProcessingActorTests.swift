import XCTest
@testable import ImageCropper

final class ProcessingActorTests: XCTestCase {
    
    func testConcurrencyLimit() async throws {
        let maxOperations = 3
        let actor = ProcessingActor(maxOperations: maxOperations)
        
        // Start operations up to the limit
        for _ in 0..<maxOperations {
            try await actor.checkConcurrencyLimit()
        }
        
        // Verify we're at the limit
        let activeCount = await actor.activeOperations
        XCTAssertEqual(activeCount, maxOperations)
        
        // Decrement one
        await actor.decrementCount()
        let newCount = await actor.activeOperations
        XCTAssertEqual(newCount, maxOperations - 1)
    }
    
    func testDecrementDoesNotGoBelowZero() async {
        let actor = ProcessingActor(maxOperations: 2)
        
        // Decrement when count is already 0
        await actor.decrementCount()
        let count = await actor.activeOperations
        XCTAssertEqual(count, 0)
    }
    
    func testConcurrentAccess() async throws {
        let actor = ProcessingActor(maxOperations: 5)
        let iterations = 20
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    try await actor.checkConcurrencyLimit()
                    
                    // Simulate some work
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    
                    await actor.decrementCount()
                }
            }
            
            // Wait for all tasks to complete
            for try await _ in group {
                // Tasks complete automatically
            }
        }
        
        // Verify all operations completed and count is back to 0
        let finalCount = await actor.activeOperations
        XCTAssertEqual(finalCount, 0)
    }
    
    func testCancellationDuringWait() async throws {
        let actor = ProcessingActor(maxOperations: 1)
        
        // Fill up the slot
        try await actor.checkConcurrencyLimit()
        
        // Try to add another operation in a cancellable task
        let task = Task {
            try await actor.checkConcurrencyLimit()
        }
        
        // Give it a moment to start waiting
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Cancel the waiting task
        task.cancel()
        
        // Verify the task throws cancellation error
        do {
            try await task.value
            XCTFail("Expected cancellation error")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        
        // Clean up
        await actor.decrementCount()
    }
    
    func testMaxOperationsRespected() async throws {
        let maxOperations = 2
        let actor = ProcessingActor(maxOperations: maxOperations)
        let completionCounter = CompletionCounter()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Start more tasks than the limit
            for _ in 0..<5 {
                group.addTask {
                    try await actor.checkConcurrencyLimit()
                    
                    // Check that we never exceed the limit
                    let activeOps = await actor.activeOperations
                    XCTAssertLessThanOrEqual(activeOps, maxOperations)
                    
                    // Simulate work
                    try await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    
                    await actor.decrementCount()
                    await completionCounter.increment()
                }
            }
            
            for try await _ in group {
                // Tasks complete automatically  
            }
        }
        
        let completedOperations = await completionCounter.count
        XCTAssertEqual(completedOperations, 5)
    }
}

// MARK: - Helper Actor for Thread-Safe Counting

actor CompletionCounter {
    private var _count = 0
    
    func increment() {
        _count += 1
    }
    
    var count: Int {
        _count
    }
}