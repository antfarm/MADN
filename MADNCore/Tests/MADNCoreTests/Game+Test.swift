@testable import MADNCore

extension Game.Field: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = Game.Field(value)!
    }
}

extension Game {

    func adding(_ pieces: [Field: Player]) throws -> Game {
        var game = self

        for (field, player) in pieces {
            try game.state.board.add(pieceFor: player, at: field)
        }

        return game
    }

    func rolled(_ die: DieValue) -> Game {
        var game = self
        try! game.roll(die)
        return game
    }

    func moved(_ field: Field) throws -> Game {
        var game = self
        try game.move(field: field)
        return game
    }
}
