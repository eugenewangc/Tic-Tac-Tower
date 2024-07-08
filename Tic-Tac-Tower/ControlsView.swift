//
//  EnterImmersive.swift
//  TicTacTowers2
//
//  Created by Eugene Wang on 5/31/24.
//
//
//  ContentView.swift
//  rand
//
//  Created by Eugene Wang on 5/31/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ControlsView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(ViewModel.self) private var model

    var body: some View {
        @Bindable var model = model
        
        HStack {
            
            
            VStack {
                
                Text("Tic Tac Towers")
                Toggle("Show Game Board", isOn: $model.isShowingBoard)
                    .font(.title)
                    .frame(width: 360)
                    .padding(24)
                    .glassBackgroundEffect()
                
                Button("Rotate Board") {
                    model.rotateBoard()
                    
                }
                .font(.title)
                .frame(width: 200)
                
                Toggle("Apply Game Rules", isOn: $model.enforceRules)
                    .font(.title)
                    .frame(width: 360)
                    .padding(24)
                    .glassBackgroundEffect()
                
                Text(model.enforceRules ? model.gameState.gameStatus.display : "Play Around Freely!")
                
                HStack {
                    Button("Reset Score") {
                        model.resetScore()
                    }
                    .font(.title)
                    .frame(width: 200)
                    .disabled(model.scoreA == 0 && model.scoreB == 0)
                    
                    Button("Restart Game") {
                        model.resetGame()
                    }
                    .font(.title)
                    .frame(width: 200)
                    .disabled(model.gameState.gameStatus == .ready)
                }
                
            }
//            .font(.title)
//            .frame(width: 400)
            .padding(24)
//            .glassBackgroundEffect()
//            
            .onChange(of: model.isShowingBoard) { _, newValue in
                if newValue {
                    openWindow(id: "GameSpace")
                } else {
                    dismissWindow(id: "GameSpace")
                }
            }
//            .onChange(of: showImmersiveSpace) { _, newValue in
//                Task {
//                    if newValue {
//                        switch await openImmersiveSpace(id: "GameSpace") {
//                        case .opened:
//                            immersiveSpaceIsShown = true
//                        case .error, .userCancelled:
//                            fallthrough
//                        @unknown default:
//                            immersiveSpaceIsShown = false
//                            showImmersiveSpace = false
//                        }
//                    } else if immersiveSpaceIsShown {
//                        await dismissImmersiveSpace()
//                        immersiveSpaceIsShown = false
//                    }
//                }
//            }
            
            VStack {
                Text("Blue Score: \(model.scoreA)")
//                    .opacity(model.enforceRules ? 1.0 : 0.0)
                Text("Red Score: \(model.scoreB)")
//                    .opacity(model.enforceRules ? 1.0 : 0.0)
            }
//            .frame(width: 360)
            .padding(24)
        }
        .font(.title)
//        .frame(width: 800)
        .padding(24)
        .glassBackgroundEffect()
    }
    
}

#Preview(windowStyle: .automatic) {
    ControlsView()
}
