//
//  TicTacTowers2App.swift
//  TicTacTowers2
//
//  Created by Eugene Wang on 5/30/24.
//

import SwiftUI
import RealityKitContent

@main

struct Tic_Tac_TowerApp: App {
    
    @StateObject var model = ViewModel()
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        RealityKitContent.TowerComponent.registerComponent()
        RealityKitContent.BoardHighlightComponent.registerComponent()
        RealityKitContent.GestureComponent.registerComponent()
        RealityKitContent.MainBoardComponent.registerComponent()
    }
    
    var body: some Scene {
        
        WindowGroup(id: "GameSpace") {
//            if #available(visionOS 2.0, *) {
//                GameView()
//                    .environment(model)
//                    .ornament(attachmentAnchor: .scene(.topBack)) {
//                        ScoreView()
//                            .environment(model)
//                            .opacity(model.enforceRules ? 1.0 : 0.0)
//                        
//                    }
//                    .toolbar {
//                        ToolbarItemGroup(placement:.bottomOrnament) {
//                            //                            HStack {
//                            Toggle(model.enforceRules ? "Game Mode ON" : "Game Mode OFF", isOn: $model.enforceRules)
//                                .onChange(of: model.enforceRules) {
//                                    if model.enforceRules == true {
//                                        model.resetGame()
//                                    }
//                                }
//                            
//                            
//                            Button("Reset Board") {
//                                model.resetGame()
//                            }
//                            .disabled(model.gameState.gameStatus == .ready || model.enforceRules)
//                        }
//                    }
//            } else {
                GameView()
                    .environment(model)
                    .toolbar {
                        ToolbarItemGroup(placement:.bottomOrnament) {
                            Toggle(model.enforceRules ? "Game Mode: ON" : "Game Mode: OFF", isOn: $model.enforceRules)
                                .onChange(of: model.enforceRules) {
                                    if model.enforceRules == true {
                                        model.resetGame()
                                        openWindow(id: "ScoreView")
                                    } else {
                                        dismissWindow(id: "ScoreView")
                                    }
                                }
                            
                            Button("Reset Board") {
                                model.resetGame()
                            }
                            .disabled(model.gameState.gameStatus == .ready || model.enforceRules)
                        }
                    }
//            }
        }
        .windowStyle(.volumetric)
        .defaultSize(model.volDefaultSize, in: .meters)
        .windowResizability(.contentSize)
        .onChange(of: scenePhase) {
//            print("scenePhase: \(scenePhase)")
            if #unavailable(visionOS 2.0) {
                if scenePhase == .background {
                    dismissWindow(id: "ScoreView")
                }
            }
        }
        
        WindowGroup(id: "ScoreView") {
            ScoreView()
                .environment(model)
        }
        .windowResizability(.contentSize)
        .onChange(of: scenePhase) {
            print("scenePhase: \(scenePhase)")
            if scenePhase == .background {
                model.enforceRules = false
            }
        }
//
//        WindowGroup(id: "GameControl") {
//            ControlsView()
//                .environment(model)
//        }
//        .windowStyle(.plain)
//        .defaultSize(width: model.winWidth, height: model.winHeight)

//        ImmersiveSpace(id: "GameSpace") {
//            GameView()
//                .environment(model)
//        }
    }
}
