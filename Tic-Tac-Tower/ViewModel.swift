//
//  ViewModel.swift
//  TicTacTowers2
//
//  Created by Eugene Wang on 5/31/24.
//



import Foundation
import ARKit
import RealityKit
import RealityKitContent
import SwiftUI
// View model

@Observable
@MainActor class ViewModel: ObservableObject {
    
    
    let emitterDefaults:[TowerSize:EmitterParam] = [
        .large: EmitterParam(shapeSize: [0.075, 0.075, 0.075], lifeSpan: 0.4, lifeSpanVar: 0.13, birthRate: 230, particleSize: 0.03),
        .medium: EmitterParam(shapeSize: [0.052, 0.052, 0.052], lifeSpan: 0.31, lifeSpanVar: 0.10, birthRate: 100, particleSize: 0.025),
        .small: EmitterParam(shapeSize: [0.032, 0.032, 0.032], lifeSpan: 0.25, lifeSpanVar: 0.05, birthRate: 45, particleSize: 0.02)]
    
    var first_onEnd: Bool = true
    
    let volDefaultSize: Size3D = Size3D(width: 0.65, height: 0.22, depth: 0.47)
    var aiTowerDropHeightDefault: SIMD3<Float> = [0, 0.2, 0]
    
    var adjScale: Float = 1
    let compScale: Float = 0.17
    
    let startingOrientation: simd_quatf = simd_quatf(angle: -.pi/2, axis: [1,0,0]) *
                                            simd_quatf(angle: -.pi/2, axis: [0,0,1]) // * .zero, [0,0,1] => blue facing me
    var rotateIndex: Int = 3 // 0 goes with .zero, [0,0,1], 1 goes with .pi/2 [0,0,1]
    func rotateBoard() {
        self.rotateIndex = (self.rotateIndex + 1) % 4
        rootEntity?.orientation *=  simd_quatf(angle: .pi/2, axis: [0,0,1])
//        print("rotate index \(rotateIndex)")
    }
    
    var boardPosition: SIMD3<Float> {
        let default_ : SIMD3<Float> = [0, -Float(volDefaultSize.height)/2.2, 0] //-Float(volHeight)/1836/2
        return rotateCoordinate( default_)
    }
    
    
    func rotateCoordinate(_ coordinate:SIMD3<Float>) -> SIMD3<Float> {
        switch self.rotateIndex {
        case 0:
            return coordinate
        case 1:
            return [-coordinate.z, coordinate.y, coordinate.x]
        case 2:
            return [-coordinate.x, coordinate.y, -coordinate.z]
        case 3:
            return [coordinate.z, coordinate.y, -coordinate.x]
        default:
            return coordinate
        }
    }
    
    func adjustDragLocation(location:SIMD3<Float>) -> SIMD3<Float> {
        let immerToVolum: SIMD3<Float> = [0, 0, Float(self.volDefaultSize.depth) * adjScale / 2]
//        print("immerToVolum \(immerToVolum)")
        let centered = location - boardPosition * adjScale - immerToVolum
//        print("centered \(centered)")
        return rotateCoordinate(centered / compScale / adjScale)
    }
    
    var isShowingBoard: Bool = false
    var rootEntity: Entity? = nil
    var gameState: GameState = .init(towerComponents: [])
    var enforceRules: Bool = false

    var aiOpponent: AIOpponent = .init()
    var vsAI: Bool = true
    
//    var vsHuman: Bool = false

    
    var scoreA: Int = 0
    var scoreB: Int = 0
    
    func setupGameState() {
        var towerComponents:[TowerComponent] = []
        self.rootEntity?.scene?.performQuery(EntityQuery(where: .has(TowerComponent.self))).forEach { entity in
            towerComponents.append(entity.components[TowerComponent.self]!)
        }
        self.gameState = GameState(towerComponents:towerComponents)
    }

    func winningTowersFire(isEmitting: Bool) {
//        print("trying to set to \(isEmitting)")
        
        self.rootEntity?.scene?.performQuery(EntityQuery(where: .has(TowerComponent.self))).forEach { towerEntity in
            guard let towerComponent: TowerComponent = towerEntity.components[TowerComponent.self] else { fatalError("no tower comp found") }
//            print("found \(towerComponent.homePosition)")
//            print("looping over \(self.gameState.winningTowerComponents)")
            self.gameState.winningTowerComponents.forEach { targetTowerComponent in
//                print("comparing to \(targetTowerComponent?.homePosition)")
                if targetTowerComponent?.homePosition == towerComponent.homePosition {
//                    print("match!")
                    guard var particleEmitterComponent: ParticleEmitterComponent = towerEntity.components[ParticleEmitterComponent.self] else { fatalError("no particle emitt comp found") }
                    particleEmitterComponent.isEmitting = isEmitting
//                    particleEmitterComponent.duration. = 2.9 //set from reality composer pro
                    particleEmitterComponent.restart()
//                    print("ismEmitting set to \(isEmitting)")
                    towerEntity.components.set(particleEmitterComponent)
                    
                }
            }
        }
        
        if isEmitting {
            self.rootEntity?.scene?.performQuery(EntityQuery(where: .has(MainBoardComponent.self))).forEach { boardEntity in
                print("hi")
                GameSound.win.play(on: boardEntity)
            }
        }
    }
    
    func updateOpacity(position: TowerPosition, size: TowerSize, opacity:Float) {
        self.rootEntity?.scene?.performQuery(EntityQuery(where: .has(BoardHighlightComponent.self))).forEach { hightlightEntity in
            if hightlightEntity.components[BoardHighlightComponent.self]?.position == position &&
                hightlightEntity.components[BoardHighlightComponent.self]?.size == size {
                hightlightEntity.components.set(OpacityComponent(opacity: opacity))
                return
            }
        }
    }
    
    func resetGame() {
        self.rootEntity?.scene?.performQuery(EntityQuery(where: .has(TowerComponent.self))).forEach { entity in
            entity.components[TowerComponent.self]?.position = entity.components[TowerComponent.self]?.homePosition ?? .a1
            
            var transform = entity.transform
//            print("transform: \(transform), position: \(entity.position), scneposition: \(entity.scenePosition)")

            // Update the translation component of the transform to move the entity
            transform.translation = entity.components[TowerComponent.self]?.homePosition.getLocation3d() ?? .zero

            // Define an animation using FromToByAnimation
            let animationDefinition = FromToByAnimation(to: transform, bindTarget: .transform)

            // Create an AnimationView using the defined animation with a delay
            let animationViewDefinition = AnimationView(source: animationDefinition, delay: 0, speed: 1)

            // Generate an AnimationResource from the AnimationViewDefinition
            let animationResource = try! AnimationResource.generate(with: animationViewDefinition)

            entity.playAnimation(animationResource)
        }
        self.winningTowersFire(isEmitting: false)
        self.setupGameState()
        self.aiOpponent = .init()
//        self.aiOpponent.aiGoesFirst = false
//        self.aiOpponent.AIsPlayer = .playerB
        self.first_onEnd = true
    }
    
    func incrementScore(player:Player) {
        if player == .playerA { self.scoreA += 1}
        else if player == .playerB { self.scoreB += 1}
    }
    func resetScore() {
        self.scoreA = 0
        self.scoreB = 0
    }
    
    func setupAudio() {
        Task {
            for effect in GameSound.allCases {
                let resource = try await AudioFileResource(named: "\(effect.rawValue).mp3")
                GameSound.soundForEffect[effect] = resource
            }
            print("here", GameSound.soundForEffect)
        }
    }
    
    func recordHumanMove(lastHumanMoveTowerComp: TowerComponent, endPosition: TowerPosition) {
        // tell AI about human's last move
        self.aiOpponent.recordMove(size: lastHumanMoveTowerComp.size, tile: endPosition, player: lastHumanMoveTowerComp.owner)
    }
    
    func makeAImove() {
        print("AI moving....")
        // get ai's next move
        var aiNextMove: (TowerPosition, TowerSize) = self.aiOpponent.getAIsNextMove()
        var homePos: TowerPosition = self.getAIsAvailableTowerHomePositionBySize(size: aiNextMove.1)
        print("ai's next move \(aiNextMove), homePos: \(homePos)")
        
        //execute ai's next move
        // 1. entity position change
        var aiTowerComponent: TowerComponent? = self.aiTowerEntityMove(homePosition: homePos, endPosition: aiNextMove.0)
        
        // 2. update gamestate
        let prevStatus: GameStatus = self.gameState.gameStatus
        print("aiTowerComponent: \(aiTowerComponent!)")
        
        self.gameState.moveAndUpdateNextPlayer(towerComponent: aiTowerComponent!, endPosition: aiNextMove.0)
        
        let currStatus: GameStatus = self.gameState.gameStatus
        print("prev gameStatus: \(prevStatus), curr gameStatus: \(currStatus)")
        if prevStatus == .blueTurn || prevStatus == .redTurn {
            if currStatus == .blueWin { self.scoreA += 1 }
            else if currStatus == .redWin { self.scoreB += 1 }
            if currStatus == .blueWin || currStatus == .redWin {
                self.gameState.saveWinningTowerComp()
                self.winningTowersFire(isEmitting: true)
            }
        }
        // 3. record in aiOppnent
        self.aiOpponent.recordMove(size: aiTowerComponent?.size ?? .large , tile: aiNextMove.0, player: aiTowerComponent?.owner ?? .playerA)
    }
    
    func getAIsAvailableTowerHomePositionBySize(size: TowerSize) -> TowerPosition {
        print("running getAIsAvailableTowerHomePositionBySize()... AIsPlayer:\(aiOpponent.AIsPlayer)")
        if aiOpponent.AIsPlayer == .playerA {
            if size == .large {
                if self.gameState.state[.a1]?.lastPlay != nil {
                    return .a1
                } else if self.gameState.state[.a2]?.lastPlay != nil {
                    return .a2
                }
            } else if size == .medium {
                if self.gameState.state[.a3]?.lastPlay != nil {
                    return .a3
                } else if self.gameState.state[.a4]?.lastPlay != nil {
                    return .a4
                }
            } else if size == .small {
                if self.gameState.state[.a5]?.lastPlay != nil {
                    return .a5
                } else if self.gameState.state[.a6]?.lastPlay != nil {
                    return .a6
                }
            }
        } else {
            if size == .large {
                if self.gameState.state[.b1]?.lastPlay != nil {
                    return .b1
                } else if self.gameState.state[.b2]?.lastPlay != nil {
                    return .b2
                }
            } else if size == .medium {
                if self.gameState.state[.b3]?.lastPlay != nil {
                    return .b3
                } else if self.gameState.state[.b4]?.lastPlay != nil {
                    return .b4
                }
            } else if size == .small {
                if self.gameState.state[.b5]?.lastPlay != nil {
                    return .b5
                } else if self.gameState.state[.b6]?.lastPlay != nil {
                    return .b6
                }
            }
        }
        print("something wrong with getAIsAvailableTowerHomePositionBySize()")
        return .a1
    }
    
    func aiTowerEntityMove(homePosition: TowerPosition, endPosition: TowerPosition) -> TowerComponent? {
        var towerComp: TowerComponent?
        print("run aiTowerEntityMove()...")
        self.rootEntity?.scene?.performQuery(EntityQuery(where: .has(TowerComponent.self))).forEach { entity in
            
            if entity.components[TowerComponent.self]?.homePosition == homePosition {
                
                
                print("entity curr position \(entity.components[TowerComponent.self]?.position)")
                print("entity curr location \(entity.position)")

                var transform = entity.transform
                
                
                // Update the translation component of the transform to move the entity
                var endLocation = endPosition.getLocation3d()
//                transform.translation = endLocation + self.aiTowerDropHeightDefault * self.adjScale
//                print("entity drop location \(transform.translation)")
//                // Define an animation using FromToByAnimation
//                var animationDefinition = FromToByAnimation(to: transform, bindTarget: .transform)
//                // Create an AnimationView using the defined animation with a delay
//                var animationViewDefinition = AnimationView(source: animationDefinition, delay: 0, speed: 1)
//                // Generate an AnimationResource from the AnimationViewDefinition
//                var animationResource = try! AnimationResource.generate(with: animationViewDefinition)
//                entity.playAnimation(animationResource)
                
                transform.translation = endLocation
                print("entity drop location \(transform.translation)")
                // Define an animation using FromToByAnimation
                let animationDefinition = FromToByAnimation(to: transform, bindTarget: .transform)
                // Create an AnimationView using the defined animation with a delay
                let animationViewDefinition = AnimationView(source: animationDefinition, delay: 0, speed: 1)
                // Generate an AnimationResource from the AnimationViewDefinition
                let animationResource = try! AnimationResource.generate(with: animationViewDefinition)
                entity.playAnimation(animationResource)
                
                print("entity end position \(entity.components[TowerComponent.self]?.position)")
                
                
                towerComp = entity.components[TowerComponent.self]!
                print("towerComp: \(towerComp)")
            }
        }
        return towerComp
    }
    
}

public struct EmitterParam {
    var shapeSize: SIMD3<Float> = [0,0,0]
    var lifeSpan: Double = 0.0
    var lifeSpanVar: Double = 0.0
    var birthRate: Float = 0.0
    var particleSize: Float = 0.0
}


//private extension ModelEntity {
//    class func createFingertip() -> ModelEntity {
//        let entity = ModelEntity(
//            mesh: .generateSphere(radius: 0.005),
//            materials: [UnlitMaterial(color: .cyan)],
//            collisionShape: .generateSphere(radius: 0.005),
//            mass: 0.0
//        )
//        
//        entity.components.set(PhysicsBodyComponent(mode: .kinematic))
//        entity.components.set(OpacityComponent(opacity: 0.0))
//        
//        return entity
//    }
//}
