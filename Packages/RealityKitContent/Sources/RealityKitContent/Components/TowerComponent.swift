import RealityKit

public enum TowerSize: String, Codable, CaseIterable {
    case large, medium, small
    var name: String { rawValue.capitalized }
}

public enum Player: String, Codable, CaseIterable {
    case playerA, playerB, none
    var name: String { rawValue.capitalized }
}

public enum TowerPosition: String, Codable, CaseIterable {
    case a1, a2, a3, a4, a5, a6, b1, b2, b3, b4, b5, b6, p1, p2, p3, p4, p5, p6, p7, p8, p9, outside
    var name: String { rawValue.capitalized }
    public func isP1ToP9() -> Bool {
        return self.rawValue.hasPrefix(("p"))
    }
    public func isA() -> Bool {
        return self.rawValue.hasPrefix(("a"))
    }
    public func isB() -> Bool {
        return self.rawValue.hasPrefix(("b"))
    }
    public func getLocation3d() -> SIMD3<Float> {
        switch self {
        case .a1: return SIMD3<Float>(x: -0.759429, y: 0.0305, z: 1.3)
        case .a2: return SIMD3<Float>(x: -0.347095, y: 0.0305, z: 1.3)
        case .a3: return SIMD3<Float>(x: 0.018714, y: 0.0305, z: 1.3)
        case .a4: return SIMD3<Float>(x: 0.337286, y: 0.0305, z: 1.3)
        case .a5: return SIMD3<Float>(x: 0.613857, y: 0.0305, z: 1.3)
        case .a6: return SIMD3<Float>(x: 0.848429, y: 0.0305, z: 1.3)
        case .b1: return SIMD3<Float>(x: -0.759429, y: 0.0305, z: -1.3)
        case .b2: return SIMD3<Float>(x: -0.347095, y: 0.0305, z: -1.3)
        case .b3: return SIMD3<Float>(x: 0.018714, y: 0.0305, z: -1.3)
        case .b4: return SIMD3<Float>(x: 0.337286, y: 0.0305, z: -1.3)
        case .b5: return SIMD3<Float>(x: 0.613857, y: 0.0305, z: -1.3)
        case .b6: return SIMD3<Float>(x: 0.848429, y: 0.0305, z: -1.3)
        case .p1: return SIMD3<Float>(x: -0.61, y: 0.0503, z: -0.61)
        case .p2: return SIMD3<Float>(x: 0, y: 0.0503, z: -0.61)
        case .p3: return SIMD3<Float>(x: 0.61, y: 0.0503, z: -0.61)
        case .p4: return SIMD3<Float>(x: -0.61, y: 0.0503, z: 0)
        case .p5: return SIMD3<Float>(x: 0, y: 0.0503, z: 0)
        case .p6: return SIMD3<Float>(x: 0.61, y: 0.0503, z: 0)
        case .p7: return SIMD3<Float>(x: -0.61, y: 0.0503, z: 0.61)
        case .p8: return SIMD3<Float>(x: 0, y: 0.0503, z: 0.61)
        case .p9: return SIMD3<Float>(x: 0.61, y: 0.0503, z: 0.61)
        case .outside: return SIMD3<Float>(x: 0, y: 0.5, z: 0)
        }
    }
}

// Ensure you register this component in your app’s delegate using:
// TowerComponent.registerComponent()
public struct TowerComponent: Component, Codable {
    public var owner: Player = .playerA
    public var position: TowerPosition = .a1
    public var homePosition: TowerPosition = .a1
    public var size: TowerSize = .large
    public var none: Bool = false
    
    public func getTowerPosition(location: SIMD3<Float>) -> TowerPosition {
        
        let right_most_x: Float = 1.015
        let left_most_x: Float = -1.015
        let furthest_z: Float = -1.54
        let closest_z: Float = 1.54
        let bottom_most_y_large: Float = -0.2935
        let bottom_most_y_medium: Float = -0.1895
        let bottom_most_y_small: Float = -0.108
        
        let plateA_board_z: Float = 1.015
        let plateB_board_z: Float = -1.015
        let divider1_z: Float = -0.305
        let divider2_z: Float = 0.305
        let divider3_x: Float = -0.305
        let divider4_x: Float = 0.305
        
        let lg_lg_divider_x: Float = -0.5532620
        let lg_md_divider_x: Float = -0.1406905
        let md_md_divider_x: Float = 0.1780000
        let md_sm_divider_x: Float = 0.4966905
        let sm_sm_divider_x: Float = 0.7311430
        
        
        // out of bounds
        if location.x >
            right_most_x || location.x < left_most_x || location.z < furthest_z || location.z > closest_z ||
            (size == .large && location.y < bottom_most_y_large) || (size == .medium && location.y < bottom_most_y_medium) ||
            (size == .small && location.y < bottom_most_y_small ) {
            return .outside
        }
        
        // plate A
        if location.z > plateA_board_z {
            if location.x < lg_lg_divider_x {
                return .a1
            } else if location.x < lg_md_divider_x {
                return .a2
            } else if location.x < md_md_divider_x {
                return .a3
            } else if location.x < md_sm_divider_x {
                return .a4
            } else if location.x < sm_sm_divider_x {
                return .a5
            } else {
                return .a6
            }
        }
        
        // plate B
        if location.z < plateB_board_z {
            if location.x < lg_lg_divider_x {
                return .b1
            } else if location.x < lg_md_divider_x {
                return .b2
            } else if location.x < md_md_divider_x {
                return .b3
            } else if location.x < md_sm_divider_x {
                return .b4
            } else if location.x < sm_sm_divider_x {
                return .b5
            } else {
                return .b6
            }
        }
        
        // board
        if location.z < divider1_z {
            // first row: p1, p2, p3
            if location.x < divider3_x {
                    return .p1
            } else if location.x < divider4_x {
                    return .p2
            } else {
                    return .p3
            }
        } else if location.z < divider2_z {
            // second row: p4, p5, p6
            if location.x < divider3_x {
                    return .p4
            } else if location.x < divider4_x {
                    return .p5
            } else {
                    return .p6
            }
        } else {
            // third row: p7, p8, p9
            if location.x < divider3_x {
                    return .p7
            } else if location.x < divider4_x {
                    return .p8
            } else {
                    return .p9
            }
        }
        
    }
    
    init() {
    }
}
