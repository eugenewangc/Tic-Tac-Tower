import RealityKit

// Ensure you register this component in your app’s delegate using:
// BoardHighlightComponent.registerComponent()
public struct BoardHighlightComponent: Component, Codable {
    public var position: TowerPosition = .p1
    public var size: TowerSize = .large
}
