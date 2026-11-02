@testable import MADNCore

extension Game {

    func adding(_ pieces: [String: Player]) -> Game {
        var game = self
        game.state.pieces.merge(pieces.map { (Field($0.key)!, $0.value) }) { _, new in new }
        return game
    }

    func rolled(_ die: Int?) -> Game {
        var game = self
        game.state.die = die
        return game
    }

    func moved(_ field: String) throws -> Game {
        var game = self
        try game.move(field: field)
        return game
    }
}
