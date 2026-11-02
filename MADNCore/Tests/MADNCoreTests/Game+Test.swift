@testable import MADNCore

extension Game {

    func adding(_ pieces: [String: GameEngine.Player]) -> Game {
        var game = self
        game.engine.pieces.merge(pieces.map { (GameEngine.Field($0.key)!, $0.value) }) { _, new in new }
        return game
    }

    func rolled(_ die: Int?) -> Game {
        var game = self
        game.engine.die = die
        return game
    }

    func moved(_ field: String) throws -> Game {
        var game = self
        try game.move(field: field)
        return game
    }
}
