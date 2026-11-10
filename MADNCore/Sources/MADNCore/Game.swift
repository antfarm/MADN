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

    public var activePlayers: Set<Player> { Rules.activePlayers(in: state) }

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

public enum GameError: Error, Equatable, CustomStringConvertible {
    case tooFewPlayers
    case startingPlayerNotInGame
    case fieldOccupied(Game.Field)
    case wrongField(Game.Player, Game.Field)
    case tooManyPieces(Game.Player)
    case noPiece(Game.Field)
    case fieldNotOnPath
    case dieNotRolled
    case dieAlreadyRolled
    case cannotMove(Game.Field)
    case movePossible

    public var description: String {
        switch self {
        case .tooFewPlayers: "A game needs at least 2 players"
        case .startingPlayerNotInGame: "Starting player must be one of the players"
        case .fieldOccupied(let field): "\(field) is occupied"
        case .wrongField(let player, let field): "Player \(player.rawValue) cannot be on \(field)"
        case .tooManyPieces(let player): "Player \(player.rawValue) has too many pieces"
        case .noPiece(let field): "No piece on \(field)"
        case .fieldNotOnPath: "Field not on player's path"
        case .dieNotRolled: "Die not rolled"
        case .dieAlreadyRolled: "Die already rolled"
        case .cannotMove(let field): "\(field) cannot move"
        case .movePossible: "A move is possible"
        }
    }
}
