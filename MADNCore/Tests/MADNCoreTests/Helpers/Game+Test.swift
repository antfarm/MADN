@testable import MADNCore

extension Game.Field: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = Game.Field(value)!
    }
}

extension Game {

    func adding(_ pieces: PiecePositions) throws -> Game {
        var game = self

        for (player, fields) in pieces {
            for field in fields {
                try game.state.board.add(pieceFor: player, at: field)
            }
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

    func passed() throws -> Game {
        var game = self
        try game.pass()
        return game
    }
}
