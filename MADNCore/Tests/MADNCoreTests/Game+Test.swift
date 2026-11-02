@testable import MADNCore

extension GameAPI {

    func adding(_ pieces: [String: Game.Player]) -> GameAPI {
        var game = self
        game.engine.pieces.merge(pieces.map { (Game.Field($0.key)!, $0.value) }) { _, new in new }
        return game
    }

    func rolled(_ die: Int?) -> GameAPI {
        var game = self
        game.engine.die = die
        return game
    }

    func moved(_ field: String) throws -> GameAPI {
        var game = self
        try game.move(field: field)
        return game
    }
}
