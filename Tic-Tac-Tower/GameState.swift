import RealityKitContent


public enum GameStatus {
    case ready, blueTurn, redTurn, blueWin, redWin, draw
    var display: String {
        switch self {
        case .ready:
            return "Move Any Tower to Start"
        case .blueTurn:
            return "Blue's Turn"
        case .redTurn:
            return "Red's Turn"
        case .blueWin:
            return "Blue Won"
        case .redWin:
            return "Red Won"
        case .draw:
            return "Draw!"
        }
    }
}

struct GameState {
    
    struct TileState {
        var playedTowers: [TowerSize: TowerComponent?] = [.large: nil, .medium: nil, .small: nil]
        
        var lastPlay: TowerComponent? {
            if playedTowers[.large] ?? nil != nil {
                return playedTowers[.large] ?? nil
            } else if playedTowers[.medium] ?? nil != nil {
                return playedTowers[.medium] ?? nil
            } else if playedTowers[.small] ?? nil != nil {
                return playedTowers[.small] ?? nil
            } else {
                return nil
            }
        }
    }
    
    var nextPlayer: Player = .playerA
    var state: [TowerPosition:TileState] = [:]
    var winningTowerComponents: [TowerComponent?] = []
    
    mutating func saveWinningTowerComp() {
        for combo in winningCombos {
            let c0 = self.state[combo.0]?.lastPlay?.owner
            let c1 = self.state[combo.1]?.lastPlay?.owner
            let c2 = self.state[combo.2]?.lastPlay?.owner
            if  c0 != nil && c0 == c1 && c1 == c2 {
                winningTowerComponents = [self.state[combo.0]?.lastPlay, self.state[combo.1]?.lastPlay, self.state[combo.2]?.lastPlay]
            }
        }
    }
    
    let winningCombos: [(TowerPosition, TowerPosition, TowerPosition)] = [
        (.p1, .p2, .p3), (.p4, .p5, .p6), (.p7, .p8, .p9), (.p1, .p4, .p7), (.p2, .p5, .p8), (.p3, .p6, .p9), (.p1, .p5, .p9), (.p3, .p5, .p7)
    ]
    let mainBoardTiles: [TowerPosition] = [.p1, .p2, .p3, .p4, .p5, .p6, .p7, .p8, .p9]
    let playerAPlateTiles: [TowerPosition] = [.a1, .a2, .a3, .a4, .a5, .a6]
    let playerBPlateTiles: [TowerPosition] = [.b1, .b2, .b3, .b4, .b5, .b6]
    
    init(towerComponents:[TowerComponent]) {
        for tpos in mainBoardTiles { self.state[tpos] = TileState() }
        for tcomp in towerComponents {
            var ts = TileState()
            ts.playedTowers[tcomp.size] = tcomp
            self.state[tcomp.homePosition] = ts
        }
    }
    
    var gameStatus: GameStatus {
        
        // game has winner
        for combo in winningCombos {
            let c0 = self.state[combo.0]?.lastPlay?.owner
            let c1 = self.state[combo.1]?.lastPlay?.owner
            let c2 = self.state[combo.2]?.lastPlay?.owner
            if  c0 != nil && c0 == c1 && c1 == c2 {
                return c0 == .playerA ? .blueWin : .redWin
            }
        }

        var num_empty = 0
        for ps in mainBoardTiles {
            if state[ps]?.lastPlay == nil {
                num_empty += 1
            }
        }
        
        // start of game, empty board
        if num_empty == 9 { return .ready }
        
        // no winner, game still going
        for ps in nextPlayer == .playerA ? playerAPlateTiles : playerBPlateTiles {
            if (state[ps]?.lastPlay != nil && state[ps]?.lastPlay?.size != .small) || num_empty > 0 {
                return nextPlayer == .playerA ? .blueTurn : .redTurn
            }
        }
        
        // no possible plays left, a draw
        return .draw
    }
    

    func isLegalMove(towerComponent:TowerComponent, endPosition:TowerPosition) -> Bool {
        let lastPlay = self.state[endPosition]?.lastPlay
        
        if endPosition.isP1ToP9() {
            if lastPlay == nil ||
                (lastPlay?.size == .medium && towerComponent.size == .large) ||
                (lastPlay?.size == .small && towerComponent.size != .small) ||
                (lastPlay?.owner == towerComponent.owner && lastPlay?.homePosition == towerComponent.homePosition) {
                return true
            }
        } else if endPosition != .outside && endPosition == towerComponent.homePosition {
            // is one of players plate AND dragged tower belongs to it
            return true
            
        }
        return false
        
    }
    
    
    // only concerns p1-p9
    mutating func moveAndUpdateNextPlayer(towerComponent:TowerComponent, endPosition:TowerPosition) {
        print("run gameState.move() ...from/to \(towerComponent.position) \(endPosition)")
        print("params: \(towerComponent), \(endPosition)")
        if towerComponent.position != endPosition {
            // remove
            self.state[towerComponent.position]?.playedTowers[towerComponent.size] = nil
            
            // add
            self.state[endPosition]?.playedTowers[towerComponent.size] = towerComponent
            
            print("endPosition.isP1ToP9() \(endPosition.isP1ToP9()), towerComponent.position.isP1ToP9(): \(towerComponent.position.isP1ToP9())")
            if endPosition.isP1ToP9() {
                if !towerComponent.position.isP1ToP9() {
                    if towerComponent.owner == .playerA {
                        self.nextPlayer = .playerB
                    } else {
                        self.nextPlayer = .playerA
                    }
                }
            }
        }
    }
    
}


struct AIOpponent {
    var AIsPlayer: Player = .playerB
    var aiGoesFirst: Bool = false
    var forPlayableTiles: [TowerSize: [TowerPosition: Bool]] = [:]
    var forPlayableTowers: [TowerSize : Int] = [.large: 2, .medium: 2, .small: 2]
    var otherPlayableTiles: [TowerSize: [TowerPosition: Bool]] = [:]
    var otherPlayableTowers: [TowerSize : Int] = [.large: 2, .medium: 2, .small: 2]
    var state_: [TowerPosition: Player] = [:]
    let boardTiles: [TowerPosition] = [.p1, .p2, .p3, .p4, .p5, .p6, .p7, .p8, .p9]
    
    
    let stepsToWinCombo: [(TowerPosition, TowerPosition, TowerPosition)] = [
        (.p1, .p2, .p3), (.p1, .p4, .p7), (.p1, .p5, .p9),
        (.p2, .p5, .p8),
        (.p3, .p2, .p1), (.p3, .p6, .p9), (.p3, .p5, .p7),
        (.p4, .p5, .p6),
        (.p6, .p5, .p4),
        (.p7, .p4, .p1), (.p7, .p5, .p3), (.p7, .p8, .p9),
        (.p8, .p5, .p2),
        (.p9, .p6, .p3), (.p9, .p8, .p7), (.p9, .p5, .p1),
        //
        (.p1, .p3, .p2), (.p1, .p7, .p4), (.p1, .p9, .p5),
        (.p2, .p8, .p5),
        (.p3, .p1, .p2), (.p3, .p9, .p6), (.p3, .p7, .p5),
        (.p4, .p6, .p5),
        (.p6, .p4, .p5),
        (.p7, .p1, .p4), (.p7, .p3, .p5), (.p7, .p9, .p8),
        (.p8, .p2, .p5),
        (.p9, .p3, .p6), (.p9, .p7, .p8), (.p9, .p1, .p5)
    ]
    

    
    
    
    init() {
        print("ai op init()")
        for size in TowerSize.allCases {
            forPlayableTiles[size] = [:]
            otherPlayableTiles[size] = [:]
            for tile in boardTiles {
                forPlayableTiles[size]![tile] = true
                otherPlayableTiles[size]![tile] = true
            }
        }
        for tile in boardTiles {
            state_[tile] = Player.none
        }
    }
    
    // record only size and endPosition(tile)
    mutating func recordMove(size:TowerSize, tile: TowerPosition, player: Player) {
        // update BOTH playableTiles at with position+size
        forPlayableTiles[.small]?[tile] = false
        otherPlayableTiles[.small]?[tile] = false
        if size == .medium {
            forPlayableTiles[.medium]?[tile] = false
            otherPlayableTiles[.medium]?[tile] = false
        }
        if size == .large {
            forPlayableTiles[.medium]?[tile] = false
            otherPlayableTiles[.medium]?[tile] = false
            forPlayableTiles[.large]?[tile] = false
            otherPlayableTiles[.large]?[tile] = false
        }
        
        // update one size in all tiles IF same-sized tower is used up
        var playableTowers = player == AIsPlayer ? self.forPlayableTowers : self.otherPlayableTowers
        var playableTiles = player == AIsPlayer ? self.forPlayableTiles : self.otherPlayableTiles
        playableTowers[size]? -= 1
        if playableTowers[size] == 0 {
            if size == .large { // no more large tower
                for tile in boardTiles {
                    playableTiles[.large]?[tile] = false
                }
            } else if size == .medium { // no more medium
                for tile in boardTiles {
                    playableTiles[.medium]?[tile] = false
                }
            } else if size == .small { // no more small
                for tile in boardTiles {
                    playableTiles[.small]?[tile] = false
                }
            }
        }
        if player == AIsPlayer {
            self.forPlayableTowers = playableTowers
            self.forPlayableTiles = playableTiles
        } else {
            self.otherPlayableTowers = playableTowers
            self.otherPlayableTiles = playableTiles
        }

        // update state_
        state_[tile] = player
        print("move recorded in AIOpponent..")
        print("state_ : \(state_)")
        print("forPlayableTowers \(forPlayableTowers)")
        print("forPlayableTiles \(forPlayableTiles)")
        print("otherPlayableTowers \(otherPlayableTowers)")
        print("otherPlayableTiles \(otherPlayableTiles)")
    }
    
    
    func getAIsNextMove(forAI: Bool = true, hard: Bool = false) -> (TowerPosition, TowerSize) {
        let forPlayer = forAI ? AIsPlayer : (AIsPlayer == .playerA ? .playerB : .playerA)
        let otherPlayer = forAI ? (AIsPlayer == .playerA ? .playerB : .playerA) : AIsPlayer

        // one step to win, take the win
        var oneStepToWin: [(TowerPosition, TowerSize)] = []
        for combo in stepsToWinCombo {
            if state_[combo.0] == forPlayer && state_[combo.1] == forPlayer {  //if two in a line
                for size in TowerSize.allCases {
                    if forPlayableTiles[size]?[combo.2] == true { // and third one can be played (last step to win)
                        oneStepToWin.append((combo.2, size))
                    }
                }
            }
            
        }
        if !oneStepToWin.isEmpty {
            return oneStepToWin.randomElement()!
        }
        
        // defend against one step to lose
        var lastChanceToDefend: [(TowerPosition, TowerSize)] = []
        for combo in stepsToWinCombo {
            if state_[combo.0] == otherPlayer && state_[combo.1] == otherPlayer {  //if two in a line
                for size in TowerSize.allCases {
                    
                    if forPlayableTiles[size]?[combo.2] == true { // and third one can be played (to block)
                        lastChanceToDefend.append((combo.2, size))
                    }
                    if forPlayableTiles[size]?[combo.1] == true {
                        lastChanceToDefend.append((combo.1, size))
                    }
                    if forPlayableTiles[size]?[combo.0] == true {
                        lastChanceToDefend.append((combo.0, size))
                    }
                }
            }
        }
        if !lastChanceToDefend.isEmpty {
            return lastChanceToDefend.randomElement()!
        }
        
        // find a line that's winnable with 2 open tiles
        var twoMoreToWin: [(TowerPosition, TowerSize)] = []
        for combo in stepsToWinCombo {
            var c1Playable: [(TowerPosition, TowerSize)] = []
            var c2Playable: [(TowerPosition, TowerSize)] = []
            if state_[combo.0] == forPlayer {
                for size in TowerSize.allCases {
                    if forPlayableTiles[size]?[combo.1] == true { c1Playable.append((combo.1, size)) }
                }
                for size in TowerSize.allCases {
                    if forPlayableTiles[size]?[combo.2] == true { c2Playable.append((combo.2, size)) }
                }
            }
            if !c1Playable.isEmpty && !c2Playable.isEmpty {
                twoMoreToWin += c1Playable
                twoMoreToWin += c2Playable
            }
        }
        if !twoMoreToWin.isEmpty {
            return twoMoreToWin.randomElement()!
        }
        
        var odds0 = 5
        if hard { odds0 = 8 }
        if Int.random(in: 0..<odds0) != 3 { // 80% prob of running
            var p5Plays: [(TowerPosition, TowerSize)] = []
            for size in TowerSize.allCases {
                if forPlayableTiles[size]?[.p5] == true {
                    p5Plays.append((.p5, size))
                }
            }
            if !p5Plays.isEmpty {
                if Int.random(in: 0..<10) != 4 { //90% of playing
                    return p5Plays[0]
                }
                return p5Plays.randomElement()!
            }
        }
        
        var odds1 = 2
        if hard { odds1 = 1 }
        if Int.random(in: 0..<odds1) != 0 { // 50% prob of playing corner
            let corners: [TowerPosition] = [.p1, .p3, .p7, .p9]
            var cornerPlays: [(TowerPosition, TowerSize)] = []
            for c in corners {
                for size in TowerSize.allCases {
                    if forPlayableTiles[size]?[c] == true {
                        cornerPlays.append((c, size))
                        if size == .large {
                            cornerPlays.append((c, size))
                            cornerPlays.append((c, size))
                            cornerPlays.append((c, size)) // 4 times more likely to play a large
                        }
                    }
                }
            }
            if !cornerPlays.isEmpty {
                return cornerPlays.randomElement()!
            }
        }
        
        // ELSE: play sides
        let sides: [TowerPosition] = [.p2, .p4, .p6, .p8]
        var sidePlays: [(TowerPosition, TowerSize)] = []
        for c in sides {
            for size in TowerSize.allCases {
                if forPlayableTiles[size]?[c] == true {
                    sidePlays.append((c, size))
                    if size == .large {
                        sidePlays.append((c, size))
                        sidePlays.append((c, size))
                        sidePlays.append((c, size)) // 4 times more likely to play a large
                    }
                }
            }
        }
        if !sidePlays.isEmpty {
            return sidePlays.randomElement()!
        }
        
        print("something wrong in getAIsNextMove()")
        return (.p5, .large)
    }
    
}
