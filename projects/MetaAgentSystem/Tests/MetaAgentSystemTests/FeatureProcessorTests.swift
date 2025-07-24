import XCTest
@testable import MetaAgentSystem
class FeatureProcessorTests: XCTestCase {
    var mockRepository: MockFeatureRepository!
    var featureProcessor: FeatureProcessor!
    override func setUp() {
        super.setUp()
        mockRepository = MockFeatureRepository()
        featureProcessor = FeatureProcessor(featureRepository: mockRepository)
    }
    func testGetPrioritizedFeatures() {
        let features = featureProcessor.getPrioritizedFeatures()
        XCTAssertEqual(features[0].priority, 0)
        XCTAssertEqual(features[1].priority, 1)
        XCTAssertEqual(features[2].priority, 2)
    }
    func testStartProcessesAllFeaturesInOrder() {
        featureProcessor.start()
        // Verify that features are processed in order of priority
        for i in 0..<mockRepository.processedFeatures.count {
            XCTAssertEqual(mockRepository.processedFeatures[i].priority, i)
        }
    }
}
class MockFeatureRepository: FeatureRepositoryProtocol {
    var processedFeatures: [Feature] = []
    func getAllFeatures() -> [Feature] {
        return [
            Feature(id: "F-1", priority: 0, description: "Feature 1", status: "pending"),
            Feature(id: "F-2", priority: 1, description: "Feature 2", status: "pending"),
            Feature(id: "F-5", priority: 2, description: "Feature 3", status: "pending")
        ]
    }
    func processNextFeature(_ feature: Feature) {
        processedFeatures.append(feature)
    }
}