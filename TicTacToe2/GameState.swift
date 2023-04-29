//
//  GameState.swift
//  TicTacToe2
//
//  Created by Wu, Wenpan on 2023-04-28.
//

import Foundation

struct GameState: Codable {
    let playerAtTurn: String
    var field:[[String?]]
    let winningPlayer: String?
    let isBoardFull: Bool
    let connectedPlayers:[String?]
}
