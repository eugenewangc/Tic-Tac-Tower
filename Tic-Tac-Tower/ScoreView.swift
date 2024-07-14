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

struct ScoreView: View {

    
    @Environment(ViewModel.self) private var model

    var body: some View {
        @Bindable var model = model
        
        HStack {
            VStack {
                
                Text(model.aiOpponent.AIsPlayer == .playerA ? "AI" : "You")
                    .bold()
                    .opacity(model.vsAI && model.gameState.gameStatus != .ready ? 1.0 : 0.0)
                
                Text("\(model.scoreA)")
                    .font(.largeTitle)
                    .foregroundColor(Color(red: 75 / 255, green: 142 / 255, blue: 234 / 255))
                    .padding(24)
                    .frame(width:80)
                    //            .background(
                    //                Color(red: 39 / 255, green: 39 / 255, blue: 39 / 255)
                    //                    .opacity(0.2))
                    .glassBackgroundEffect()
                
            }
            
            
            VStack {
                
                HStack {
                    Text(model.gameState.gameStatus.display)
                }
                .font(.title)
                .frame(width:400)
                
                HStack {
                    Button("Reset Score") {
                        model.resetScore()
                    }
                    
                    .background(
                        Color(red: 39 / 255, green: 39 / 255, blue: 39 / 255)
                            .opacity(0.2))
                    .glassBackgroundEffect()
                    .frame(width: 150)
                    .disabled(model.scoreA == 0 && model.scoreB == 0)
                    

                    Button(model.gameState.gameStatus == .redWin || model.gameState.gameStatus == .blueWin ? "Next Game" : "Restart Game") {
                        model.resetGame()
                    }
                    .background(
                        Color(red: 39 / 255, green: 39 / 255, blue: 39 / 255)
                            .opacity(0.2))
                    .glassBackgroundEffect()
                    .frame(width: 150)
                    .disabled(model.gameState.gameStatus == .ready)
                    //                        .opacity(model.gameState.gameStatus == .ready ? 0.0 : 1.0)
                    

                }
                
                HStack {

                    Toggle(model.vsAI ? "AI Opponent: ON" : "AI Opponent: OFF", isOn: $model.vsAI)
                        .onChange(of: model.vsAI) {
                            if model.vsAI {
                                model.vsAI = true
                            } else {
                                model.vsAI = false
                            }
                        }
                        .frame(width: 230)
//                        .toggleStyle(.button)
                        .disabled(model.gameState.gameStatus != .ready)
                    
                    Button("AI goes first") {
                        model.aiOpponent.aiGoesFirst = true
                        model.aiOpponent.AIsPlayer = .playerA
                        model.makeAImove()
                    }
                    .frame(width: 150)
                    .disabled(!model.vsAI || model.gameState.gameStatus != .ready)
                }
//                .opacity(model.gameState.gameStatus == .ready ? 1.0 : 0.0)
                
            }
            
            //            .padding(24)
            VStack {
                Text(model.aiOpponent.AIsPlayer == .playerA ? "You" : "AI")
                    .bold()
                    .opacity(model.vsAI && model.gameState.gameStatus != .ready ? 1.0 : 0.0)
                
                Text("\(model.scoreB)")
                    .font(.largeTitle)
                    .foregroundColor(Color(red: 212 / 255, green: 63 / 255, blue: 65 / 255))
                    .padding(24)
                    .frame(width:80)
                    //            .background(
                    //                Color(red: 39 / 255, green: 39 / 255, blue: 39 / 255)
                    //                    .opacity(0.2))
                    .glassBackgroundEffect()
                
            }
            
        }
        .padding(20)
//        .background(.black.opacity(0.85))
//        .cornerRadius(8)
//        .background(
//            Color(red: 39 / 255, green: 39 / 255, blue: 39 / 255)
//                .opacity(0.2))
        .glassBackgroundEffect(displayMode: .implicit)
        
    }
    
}

#Preview(windowStyle: .automatic) {
    ControlsView()
}
