public struct Game {

    var state: State

    public init(
        players: Set<Player> = Set(Player.allCases),
        player: Player = .one
    ) throws {
        try self.init(pieces: Rules.initialPieces(for: players), player: player)
    }

    public init( // for tests and previews
        pieces: PiecePositions,
        player: Player = .one
    ) throws {
        state = try State(pieces: pieces, player: player)
    }

    public var player: Player { state.player }

    public var die: DieValue? { state.die }

    public func player(at field: Field) -> Player? {
        state.board.player(at: field)
    }

    public func possibleMoves() throws -> [(from: Field, to: Field)] {
        try Rules.possibleMoves(in: state)
    }

    public mutating func roll(_ die: DieValue = .random()) throws {
        state = try Rules.roll(die, in: state)
    }

    public mutating func move(field: Field) throws {
        state = try Rules.move(field: field, in: state)
    }

    public mutating func pass() throws {
        state = try Rules.pass(in: state)
    }
}

public struct GameError: Error {
    public let message: String
}
