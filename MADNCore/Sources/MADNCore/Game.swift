public struct Game: Codable {

    var state: State

    public init(
        players: Set<Player> = Set(Player.allCases),
        player: Player? = nil
    ) throws {
        let player = player ?? Player.allCases.first(where: players.contains) ?? .one
        try self.init(pieces: Rules.initialPieces(for: players), player: player)
    }

    public init( // for tests and previews
        pieces: PiecePositions,
        player: Player = .one,
        die: DieValue? = nil
    ) throws {
        state = try State(pieces: pieces, player: player, die: die)
    }

    public var player: Player { state.player }

    public var players: Set<Player> { state.players }

    public var activePlayers: Set<Player> { Rules.activePlayers(in: state) }

    public var finishedPlayers: [Player] { Rules.finishedPlayers(in: state) }

    public var isOver: Bool { Rules.isGameOver(in: state) }

    public var die: DieValue? { state.die }

    public func player(at field: Field) -> Player? {
        state.board.player(at: field)
    }

    public var actions: [Action] {
        Rules.actions(in: state)
    }

    public func target(from field: Field) -> Field? {
        Rules.target(from: field, in: state)
    }

    public mutating func apply(_ action: Action) throws {
        state = try Rules.apply(action, in: state)
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
    case actionNotOffered

    public var description: String {
        switch self {
        case .tooFewPlayers: "A game needs at least 2 players"
        case .startingPlayerNotInGame: "Starting player must be one of the players"
        case .fieldOccupied(let field): "\(field) is occupied"
        case .wrongField(let player, let field): "Player \(player.rawValue) cannot be on \(field)"
        case .tooManyPieces(let player): "Player \(player.rawValue) has too many pieces"
        case .noPiece(let field): "No piece on \(field)"
        case .fieldNotOnPath: "Field not on player's path"
        case .actionNotOffered: "Action not offered"
        }
    }
}
