@testable import MADNCore

typealias Board = Game.Board
typealias DieValue = Game.DieValue
typealias Field = Game.Field
typealias PiecePositions = Game.PiecePositions
typealias Player = Game.Player
typealias Rules = Game.Rules
typealias State = Game.State

extension Field: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = Field(value)!
    }
}

extension State {

    func adding(_ pieces: PiecePositions) throws -> State {
        var state = self

        for (player, fields) in pieces {
            for field in fields {
                try state.board.add(pieceFor: player, at: field)
            }
        }

        return state
    }

    func rolled(_ die: DieValue) -> State {
        try! Rules.apply(.roll(die), in: self)
    }

    func moved(_ field: Field) throws -> State {
        let target = Rules.target(from: field, in: self)!

        return try Rules.apply(.move(from: field, to: target), in: self)
    }

    func resumed() -> State {
        try! Rules.apply(.resume, in: self)
    }
}
