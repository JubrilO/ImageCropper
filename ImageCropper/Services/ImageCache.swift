import UIKit

protocol ImageCaching {
    func image(for imageId: UUID, cropPercentage: Double) -> UIImage?
    func store(_ image: UIImage, for imageId: UUID, cropPercentage: Double)
    func removeImage(for imageId: UUID, cropPercentage: Double)
    func removeAllImages()
}

final class ImageCache: ImageCaching {
    private let cache = NSCache<CacheKey, UIImage>()
    private let lock = NSLock()
    
    init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func image(for imageId: UUID, cropPercentage: Double) -> UIImage? {
        let key = CacheKey(imageId: imageId, cropPercentage: cropPercentage)
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: key)
    }
    
    func store(_ image: UIImage, for imageId: UUID, cropPercentage: Double) {
        let key = CacheKey(imageId: imageId, cropPercentage: cropPercentage)
        let cost = ImageDownsampler.estimatedMemoryUsage(for: image)
        
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(image, forKey: key, cost: cost)
    }
    
    func removeImage(for imageId: UUID, cropPercentage: Double) {
        let key = CacheKey(imageId: imageId, cropPercentage: cropPercentage)
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: key)
    }
    
    func removeAllImages() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
    }
    
    @objc private func handleMemoryWarning() {
        removeAllImages()
    }
}

private final class CacheKey: NSObject {
    let imageId: UUID
    let cropPercentage: Double
    
    init(imageId: UUID, cropPercentage: Double) {
        self.imageId = imageId
        self.cropPercentage = cropPercentage
        super.init()
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(imageId)
        hasher.combine(cropPercentage)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CacheKey else { return false }
        return imageId == other.imageId && cropPercentage == other.cropPercentage
    }
}