protocol FeatureRepositoryProtocol {
    func getAllFeatures() -> [Feature]
}

class FeatureRepository: FeatureRepositoryProtocol {
    // Implementation for fetching features from a database
    
    func getAllFeatures() -> [Feature] {
        // Placeholder implementation
        return []
    }
}

struct Feature {
    let id: String
    let priority: Int
    let description: String
    let status: String
}

class FeatureProcessor {
    private var featureRepository: FeatureRepositoryProtocol
    init(featureRepository: FeatureRepositoryProtocol) {
        self.featureRepository = featureRepository
    }
    func start() {
        let features = getPrioritizedFeatures()
        for feature in features {
            processNextFeature(feature)
        }
    }
    internal func getPrioritizedFeatures() -> [Feature] {
        let allFeatures = featureRepository.getAllFeatures()
        return allFeatures.sorted(by: { $0.priority < $1.priority })
    }
    private func processNextFeature(_ feature: Feature) {
        // Logic to process a single feature
        print("Processing feature: \(feature.description)")
        // Update the status of the feature as needed
    }
}