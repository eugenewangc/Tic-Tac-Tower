//
//  GameSound.swift
//  TicTacTowers2
//
//  Created by Eugene Wang on 6/26/24.
//

import RealityFoundation

public enum GameSound: String, CaseIterable {
    case pickup_1
    case pickup_2
    case pickup_3
    case drop_1
    case drop_2
    case drop_3
    case drop_4
    case drop_5
    case error_start_1
    case error_end_1
    case win
//    case win
//    case draw
    
    public static var soundForEffect: [GameSound: AudioFileResource] = [:]
    
    var gain: Double {
        switch self {
        case .pickup_1: return 10
        case .pickup_2: return 10
        case .pickup_3: return 10
        case .drop_1: return 0
        case .drop_2: return 0
        case .drop_3: return 0
        case .drop_4: return 0
        case .drop_5: return 0
        case .error_start_1: return -5
        case .error_end_1: return -5
        case .win: return 5
        }
    }
    
    public static let dropSounds: [GameSound] = [.drop_1, .drop_2, .drop_3, .drop_4, .drop_5]
    public static let pickupSounds: [GameSound] = [.pickup_1, .pickup_2, .pickup_3]
    
    /// Plays a sound effect from an entity.
    func play(on entity: Entity) {
        guard let effect = Self.soundForEffect[self] else {
            fatalError("No sound asset for sound: \(self)")
        }
        
        let audioController = entity.prepareAudio(effect)
        audioController.gain = gain
//        print("gain \(audioController.gain)")
        audioController.play()
        print("played audio")
        
    }
}
