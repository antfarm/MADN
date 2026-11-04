public struct Game {

    var state: State

    public init(pieces: [Field: Player]? = nil, player: Player = .one) throws {
        guard let pieces else {
            state = Rules.initialState(player: player)
            return
        }

        state = try State(pieces: pieces, player: player)
    }

    public var player: Player { state.player }

    public var die: DieValue? { state.die }

    public func player(at field: Field) -> Player? {
        Rules.player(at: field, in: state)
    }

    public func target(from field: Field) throws -> Field? {
        try Rules.target(from: field, in: state)
    }

    public func movablePieces() -> Set<Field> {
        Rules.movablePieces(in: state)
    }

    public mutating func roll(_ die: DieValue = .random()) {
        state = Rules.roll(die, in: state)
    }

    public mutating func move(field: Field) throws {
        state = try Rules.move(field: field, in: state)
    }
}

extension Game.Field: LosslessStringConvertible {

    public var description: String {
        switch self {
        case .track(let player, let field):
            "\(player.rawValue)\(field.index)"
        case .home(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        case .out(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        }
    }

    public init?(_ description: String) {
        guard description.count == 2,
              let digit = description.first!.wholeNumberValue,
              let player = Game.Player(rawValue: digit)
        else { return nil }

        let position = description.last!

        if let index = position.wholeNumberValue, let field = Game.Track.Field(index: index) {
            self = .track(player, field)
        }
        else if let field = Game.Home.Field(rawValue: String(position)) {
            self = .home(player, field)
        }
        else if let field = Game.Out.Field(rawValue: String(position)) {
            self = .out(player, field)
        }
        else {
            return nil
        }
    }
}
