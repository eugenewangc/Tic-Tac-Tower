//
//  ContentView.swift
//  TicTacTowers2
//
//  Created by Eugene Wang on 5/30/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @State private var scaleCoef: CGFloat = 0.2

    var body: some View {
        
        RealityView { content in
            
            let platformEntity = await createPlatformEntity()
//            platformEntity.scale *= .init(x: -1, y: 1, z: 1)
            let newScale: Float = 0.01
            platformEntity.scale = SIMD3<Float>(repeating: newScale)
            content.add(platformEntity)
            
        }
        
//        let newScale = Float.lerp(a: 0.2, b: 1.0, t: 1)
//        entity?.setScale(SIMD3<Float>(repeating: newScale), relativeTo: nil)
    }
    
    private func createPlatformEntity () async -> Entity {
        guard let platformEntity = try? await Entity(named: "Towers", in: realityKitContentBundle) else {
            fatalError("Cannot load platform model")
        }
        
        return platformEntity
    }
}

public extension FloatingPoint {
    static func lerp(a: Self, b: Self, t: Self) -> Self {
        let one = Self(1)
        let oneMinusT = one - t
        let aTimesOneMinusT = a * oneMinusT
        let bTimesT = b * t
        return aTimesOneMinusT + bTimesT
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
