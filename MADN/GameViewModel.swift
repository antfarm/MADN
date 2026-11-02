import Observation
import MADNCore

@Observable
final class GameViewModel {

    var game = Game(pieces: [
        ["0A", "0a", "00", "09"],
        ["1A", "1a", "11", "19"],
        ["2A", "2a", "22", "29"],
        ["3A", "3a", "33", "39"],
    ])

    static var allFields: Set<String> { Game.allFields }

    var player: Int { game.player }

    var die: Int? { game.die }

    var movablePieces: Set<String> { game.movablePieces() }

    func player(at field: String) -> Int? {
        game.player(at: field)
    }

    func roll() {
        game.roll(.random(in: 1...6))
    }

    func move(field: String) {
        do { try game.move(field: field) } catch { print(error) }
    }
}
