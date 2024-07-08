//
//  ImmersiveView.swift
//  TicTacTowers2
//
//  Created by Eugene Wang on 5/30/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit
import Foundation

struct GameView: View {
    
    @Environment(ViewModel.self) private var model
    
    @State private var position: Point3D = .zero
    @State private var startPosition: Point3D? = nil
    
    @Environment(\.physicalMetrics) var physicalMetrics

    static let towerEntityQuery = EntityQuery(where: .has(TowerComponent.self))
    
    var body: some View {
        @Bindable var model = model
        
        
        var targetedEntity: Entity?
        var dragStartPosition: SIMD3<Float> = .zero
        var isDragging = false
        var pivotEntity: Entity?
        var initialOrientation: simd_quatf?
        
        var userScale: Float = 1.0
        
        var currentHighlightPosition: TowerPosition = .outside
        var first_onChange: Bool = true
        
        
        GeometryReader3D { geometry in
            RealityView { content in
                
                if let scene = try? await Entity(named: "tictactower_all_v2_unjoined", in: realityKitContentBundle) {
                    model.rootEntity = scene
                    content.add(scene)
                    scene.position = model.boardPosition
                    scene.orientation = model.startingOrientation
                }
                model.setupGameState()
                model.setupAudio()
//                for effect in GameSound.allCases {
//                    guard let resource = try? AudioFileResource.load(named: "/root/drop_1_mp3",
//                                                                     from: "tictactower_all_v2_unjoined.usda",
//                                                                     in: realityKitContentBundle
//                                                                     ) else {
//                        print("\(effect.rawValue)_mp3 not found")
//                        return }
//                    GameSound.soundForEffect[effect] = resource
//                }
//                print("here", GameSound.soundForEffect)
                    
                
            } update: { content in
                
                

                
//                // calculate
//                let max = geometry.frame(in: .local).max
//                let min = geometry.frame(in: .local).min
//                if userScale != Float((max.x - min.x) / model.volDefaultSize.width) {
//                    userScale = Float((max.x - min.x) / model.volDefaultSize.width)
//                    print("calculated scale \(userScale)")
//                    model.rootEntity?.setScale([userScale, userScale, userScale], relativeTo: nil)
//                    model.rootEntity?.position = model.boardPosition * userScale
//                }
                
                let newVolSize: Float = Float(physicalMetrics.convert(geometry.size, to: .meters).width)
            
                if userScale != (newVolSize / Float(model.volDefaultSize.width)) {
                    userScale = newVolSize / Float(model.volDefaultSize.width)
//                    print("calculated scale \(userScale)")
                    model.rootEntity?.setScale([userScale, userScale, userScale], relativeTo: nil)
                    model.rootEntity?.position = model.boardPosition * userScale
                    
                    model.rootEntity?.scene?.performQuery(EntityQuery(where: .has(TowerComponent.self))).forEach { towerEntity in
                        guard var towerComponent: TowerComponent = towerEntity.components[TowerComponent.self] else { fatalError("no  tower comp found") }
                        guard var particleEmitterComponent: ParticleEmitterComponent = towerEntity.components[ParticleEmitterComponent.self] else { fatalError("no particle emitt comp found") }
                        
                        let defaults: EmitterParam = model.emitterDefaults[towerComponent.size] ?? EmitterParam()
                        particleEmitterComponent.mainEmitter.lifeSpan = defaults.lifeSpan * Double(userScale)
                        particleEmitterComponent.mainEmitter.lifeSpanVariation = defaults.lifeSpanVar * Double(userScale)
                        particleEmitterComponent.emitterShapeSize = defaults.shapeSize
                        particleEmitterComponent.mainEmitter.birthRate = defaults.birthRate * userScale * userScale
                        particleEmitterComponent.mainEmitter.size = defaults.particleSize * userScale 
                        
//                        particleEmitterComponent.restart()
                        towerEntity.components.set(particleEmitterComponent)
                    }
                        
                }
                

            }
            .simultaneousGesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        
                        //update scale
                        model.adjScale = userScale
//                        print("board location \(model.rootEntity?.position)")
                        
                        
                        // MARK: - TowerComp
                        guard let towerComponent = value.entity.components[TowerComponent.self] else { return }
                        let status: GameStatus = model.gameState.gameStatus
//                        print("illegal drag conditionals::::")
//                        print(model.enforceRules)
//                        print(towerComponent.owner, model.gameState.nextPlayer, status)
//                        print(towerComponent.position.isP1ToP9())
//                        print(model.vsAI, model.aiOpponent.aiGoesFirst)
                        if  !model.enforceRules ||
                                ((towerComponent.owner == model.gameState.nextPlayer || status == .ready) &&
                                 !(status == .draw || status == .blueWin || status == .redWin) &&
                                 !towerComponent.position.isP1ToP9() &&
                                 (!model.vsAI || (!model.aiOpponent.aiGoesFirst && status == .ready) || (towerComponent.owner != model.aiOpponent.AIsPlayer)))
                                
                        {
                            
                            // MARK: - GestureComp
                            guard let gestureComponent = value.entity.components[GestureComponent.self] else { return }
                            //
                            //                    gestureComponent.onChanged(value: value) // expanded below >>>>
                            guard gestureComponent.canDrag else { return }
                            // Only allow a single Entity to be targeted at any given time.
                            if targetedEntity == nil {
                                targetedEntity = value.entity
                                initialOrientation = value.entity.orientation(relativeTo: nil)
                            }
                            //
                            //                  handleFixedDrag(value: value) // expand below >>>>
                            guard let entity = targetedEntity else { fatalError("Gesture contained no entity") }
                            if !isDragging {
                                // MARK: - Sound Effect
                                let soundEffect: GameSound? = GameSound.pickupSounds.randomElement()
                                print("picked \(soundEffect)")
                                soundEffect?.play(on: value.entity)
                                // at first pickup
                                isDragging = true
                                dragStartPosition = entity.scenePosition
                            }
                            let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
                            let offset = SIMD3<Float>(x: Float(translation3D.x), y: Float(translation3D.y), z: Float(translation3D.z))
                            entity.scenePosition = dragStartPosition + offset
//                            print("raw tower location: \(entity.scenePosition)")
                            if let initialOrientation = initialOrientation {
                                targetedEntity?.setOrientation(initialOrientation, relativeTo: nil)
                            }
                            //
                            //                  <<<< handleFixedDrag(value: value) // expand end
                            //                  <<<< gestureComponent.onChanged(value: value) // expand end
                            value.entity.components[GestureComponent.self] = gestureComponent
                            
                            // MARK: - PhysicsComp
                            // disable physics during drag
                            //                    guard var physicsComponent = value.entity.physicsComponent else { return }
                            //                    physicsComponent.isAffectedByGravity = false
                            //                    value.entity.components.set(physicsComponent)
                            
                            // MARK: - Highlight
                            // position it's hovering over
                            var nextHighlightPosition = towerComponent.getTowerPosition(location: model.adjustDragLocation(location: entity.scenePosition))
//                            print("adjusted tower location: \(model.adjustDragLocation(location: entity.scenePosition))")
//                            print("identified tile position: \(nextHighlightPosition)")
                            // only highlight if potential move to position is legal
                            if !model.gameState.isLegalMove(towerComponent: towerComponent, endPosition: nextHighlightPosition) {
                                nextHighlightPosition = towerComponent.homePosition
                            }
                            if currentHighlightPosition != nextHighlightPosition || first_onChange {
                                model.updateOpacity(position: currentHighlightPosition, size: towerComponent.size, opacity: 0.0)
                                model.updateOpacity(position: nextHighlightPosition, size: towerComponent.size, opacity: 1.0)
                                currentHighlightPosition = nextHighlightPosition
                            }
                            first_onChange = false
                        } else {
                            
                            if !isDragging {
                                GameSound.error_start_1.play(on: value.entity)
                                print("picked \(GameSound.error_start_1)")
                                isDragging = true
                            }
                        }
                    
                        
                    }
                    .onEnded { value in
                        guard var towerComponent = value.entity.components[TowerComponent.self] else { return }
                        let status: GameStatus = model.gameState.gameStatus
                        if  !model.enforceRules ||
                                ((towerComponent.owner == model.gameState.nextPlayer || status == .ready) &&
                                 !(status == .draw || status == .blueWin || status == .redWin) &&
                                 !towerComponent.position.isP1ToP9() &&
                                 (!model.vsAI || (!model.aiOpponent.aiGoesFirst && status == .ready) || (towerComponent.owner != model.aiOpponent.AIsPlayer)))
                        {
                            
                            // MARK: - Sound Effect
                            let soundEffect: GameSound? = GameSound.dropSounds.randomElement()
                            print("picked \(soundEffect)")
                            soundEffect?.play(on: value.entity)
                            
                            // MARK: - Gesutre (onEnd)
                            guard let gestureComponent = value.entity.components[GestureComponent.self] else { return }
                            //                  gestureComponent.onEnded(value: value) // expanded below >>>>
                            isDragging = false
                            if let pivotEntity_ = pivotEntity, gestureComponent.pivotOnDrag {
                                pivotEntity_.parent!.addChild(targetedEntity!, preservingWorldTransform: true)
                                pivotEntity_.removeFromParent()
                            }
                            pivotEntity = nil
                            targetedEntity = nil
                            //                  <<<< gestureComponent.onEnded(value: value) // expand end
                            value.entity.components[GestureComponent.self] = gestureComponent
                            
                            // MARK: - Highlight (onEnd)
                            // remove highlight
                            model.updateOpacity(position: currentHighlightPosition, size: towerComponent.size, opacity: 0.0)
                            
                            // MARK: - Tower Location
                            value.entity.components[TowerComponent.self]?.position = currentHighlightPosition
                            value.entity.position = currentHighlightPosition.getLocation3d()
                            first_onChange = true

//                            towerComponent.position = currentHighlightPosition // done in gameState.move()
//                            
                            // MARK: - Game Tracking
                            
                            let prevStatus: GameStatus = model.gameState.gameStatus
                            model.gameState.moveAndUpdateNextPlayer(towerComponent: towerComponent, endPosition: currentHighlightPosition)
                            
                            let currStatus: GameStatus = model.gameState.gameStatus
                            if prevStatus == .blueTurn || prevStatus == .redTurn {
                                if currStatus == .blueWin { model.scoreA += 1 }
                                else if currStatus == .redWin { model.scoreB += 1 }
                                if currStatus == .blueWin || currStatus == .redWin {
                                    model.gameState.saveWinningTowerComp()
                                    model.winningTowersFire(isEmitting: true)
                                }
                            }
                            
                            // MARK: - A.I.
                            // auto set correct AI's player when human goes first
                            if model.first_onEnd && currStatus != .ready {
                                model.first_onEnd = false
                                if !model.aiOpponent.aiGoesFirst {
                                    model.aiOpponent.AIsPlayer = currStatus == .blueTurn ? .playerA : .playerB
                                    print("ai player set to: \( model.aiOpponent.AIsPlayer)")
                                }
                            }
                            // make AI's next move
                            print("ai section in gameView..")
                            if model.vsAI && model.enforceRules && towerComponent.position != currentHighlightPosition && ( model.gameState.gameStatus == .blueTurn ||  model.gameState.gameStatus == .redTurn) {
                                model.recordHumanMove(lastHumanMoveTowerComp: towerComponent, endPosition:currentHighlightPosition)
                                model.makeAImove()
                            }
                        
                            
                            // enable physics back on end of drag
                            //                    guard var physicsComponent = value.entity.physicsComponent else { return }
                            //                    physicsComponent.isAffectedByGravity = true
                            //                    value.entity.components.set(physicsComponent)
                        } else {
                            GameSound.error_end_1.play(on: value.entity)
                            print("picked \(GameSound.error_end_1)")
                            isDragging = false
                        }
                        
                    }
            )
            
        }
        
        
        
//        .simultaneousGesture(
//            MagnifyGesture()
//                .targetedToAnyEntity()
//                .useGestureComponent()
//        )
//        .simultaneousGesture(
//            RotateGesture3D()
//                .targetedToAnyEntity()
//                .useGestureComponent()
//        )
        
//        .task {
//            await model.requestAuthorization()
//        }
        
//        .task {
////            await model.runSession()
//            do {
//                try await session.run([sceneReconstruction, handTracking])
//            } catch {
//                print("Failed to start arkit session: \(error)")
//            }
//        }
        
//        .task {
//            // with the session now running, we can receive anchor updates
//            await model.processHandUpdates()
//        }
        
//        .task {
////            await model.processReconstructionUpdates()
//            for await update in sceneReconstruction.anchorUpdates {
//                let meshAnchor = update.anchor
//
//                // attempt to generate a ShapeResource from the MeshAnchor
//                guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor)
//                else { continue }
//
//                // then switch on the anchor update's event
//                switch update.event {
//                case .added:
//                    // if we're adding an anchor, we create a new entity, set its transform, add a collision and physics body component, then add an input target component. So that this collider can be a target for gestures
//                    let entity = ModelEntity()
//                    entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform) // meshAnchor.transform
//                    entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
//                    entity.physicsBody = PhysicsBodyComponent()
//                    entity.components.set(InputTargetComponent())
//                    // finally, we add a new entity to our map and as a child of our contentEntity
//                    meshEntities[meshAnchor.id] = entity
//                    rootEntity.addChild(entity)
//                case .updated:
//                    // to update an entity, we retrive it from the map, then update its transform and collision component shape
//                    guard let entity = meshEntities[meshAnchor.id] else { fatalError("...") }
//                    entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform) // meshAnchor.transform
//                    entity.collision?.shapes = [shape]
//                case .removed:
//                    // we remove the corresponding entity from its parent and the map
//                    meshEntities[meshAnchor.id]?.removeFromParent()
//                    meshEntities.removeValue(forKey: meshAnchor.id)
//                default:
//                    fatalError("Unsupported anchor event")
//                }
//
//            }
//        }
        


    }
    
    
}

#Preview(immersionStyle: .mixed) {
    GameView()
}
