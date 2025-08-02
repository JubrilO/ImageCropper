import Foundation

struct CropPercentage {
    private(set) var value: Double
    
    static let minimum = 5.0
    static let maximum = 20.0
    static let defaultValue = 10.0
    
    init(value: Double = Self.defaultValue) {
        self.value = Self.clamp(value)
    }
    
    mutating func update(_ newValue: Double) {
        self.value = Self.clamp(newValue)
    }
    
    private static func clamp(_ value: Double) -> Double {
        min(max(value, minimum), maximum)
    }
    
    var percentage: Double {
        value / 100.0
    }
}

extension CropPercentage: Equatable {}