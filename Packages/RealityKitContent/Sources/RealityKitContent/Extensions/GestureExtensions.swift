/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App-specific extension on Gesture.
*/

import Foundation
import RealityKit
import SwiftUI

// MARK: - Rotate -

/// Gesture extension to support rotation gestures.
public extension Gesture where Value == EntityTargetValue<RotateGesture3D.Value> {
    
    /// Connects the gesture input to the `GestureComponent` code.
    func useGestureComponent() -> some Gesture {
        onChanged { value in
            guard var gestureComponent = value.entity.gestureComponent else { return }
            
            gestureComponent.onChanged(value: value)
            
            value.entity.components.set(gestureComponent)
        }
        .onEnded { value in
            guard var gestureComponent = value.entity.gestureComponent else { return }
            
            gestureComponent.onEnded(value: value)
            
            value.entity.components.set(gestureComponent)
        }
    }
}

// MARK: - Drag -

/// Gesture extension to support drag gestures.
public extension Gesture where Value == EntityTargetValue<DragGesture.Value> {
    
    /// Connects the gesture input to the `GestureComponent` code.
    func useGestureComponent() -> some Gesture {
        onChanged { value in
            guard var gestureComponent = value.entity.gestureComponent else { return }
            gestureComponent.onChanged(value: value)
            value.entity.components.set(gestureComponent)
            
            // disable physics during drag
            guard var physicsComponent = value.entity.physicsComponent else { return }
            physicsComponent.isAffectedByGravity = false
            value.entity.components.set(physicsComponent)
            
//            // highlight board tiles on hover
//            guard var boardComponent = /*value.entity.boardComponent*/ else { return }
//            boardComponent.checkHover(towerLocation3D: [0,0,0])
//            value.entity.components.set(boardComponent)
            
        }
        .onEnded { value in
            guard var gestureComponent = value.entity.gestureComponent else { return }
            gestureComponent.onEnded(value: value)
            value.entity.components.set(gestureComponent)
            
            // enable physics back on end of drag
            guard var physicsComponent = value.entity.physicsComponent else { return }
            physicsComponent.isAffectedByGravity = true
            value.entity.components.set(physicsComponent)

        }
    }
}

// MARK: - Magnify (Scale) -

/// Gesture extension to support scale gestures.
public extension Gesture where Value == EntityTargetValue<MagnifyGesture.Value> {
    
    /// Connects the gesture input to the `GestureComponent` code.
    func useGestureComponent() -> some Gesture {
        onChanged { value in
            guard var gestureComponent = value.entity.gestureComponent else { return }
            
            gestureComponent.onChanged(value: value)
            
            value.entity.components.set(gestureComponent)
        }
        .onEnded { value in
            guard var gestureComponent = value.entity.gestureComponent else { return }
            
            gestureComponent.onEnded(value: value)
            
            value.entity.components.set(gestureComponent)
        }
    }
}
