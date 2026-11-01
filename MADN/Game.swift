import Observation
import MADNCore

@Observable
final class Game {

    var game = MADNCore.Game(pieces: [
        ["0A", "0a", "00", "09"],
        ["1A", "1a", "11", "19"],
        ["2A", "2a", "22", "29"],
        ["3A", "3a", "33", "39"],
    ])

    static func isValid(fields: Set<String>) -> Bool {
        MADNCore.Game.isValid(fields: fields)
    }

    var player: Int { game.player.rawValue }

    var die: Int? { game.die }

    var movablePieces: Set<String> { game.movablePieces() }

    func piece(at field: String) -> Int? {
        game.piece(at: field)
    }

    func roll() {
        game.roll(.random(in: 1...6))
    }

    func move(field: String) {
        do { try game.move(field: field) } catch { print(error) }
    }
}
