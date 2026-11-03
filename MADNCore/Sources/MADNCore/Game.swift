import Foundation

public struct Game {

    var state: State

    public static var allFields: Set<String> {
        Set(Field.allCases.map(\.description))
    }

    public init(pieces: [Set<String>]? = nil, player: Int = 0) throws {
        guard let player = Player(rawValue: player) else {
            throw GameError(message: "Invalid player")
        }

        guard let pieces else {
            state = Rules.initialState(player: player)
            return
        }

        guard pieces.count == Player.allCases.count else {
            throw GameError(message: "Invalid number of players")
        }

        let list = try zip(Player.allCases, pieces).flatMap { player, fieldLabels in
            try fieldLabels.map { (try Self.field(for: $0), player) }
        }

        guard Set(list.map(\.0)).count == list.count else {
            throw GameError(message: "Two pieces on one field")
        }

        state = try State(pieces: Dictionary(uniqueKeysWithValues: list), player: player)
    }

    public var player: Int { state.player.rawValue }

    public var die: Int? { state.die }

    public func player(at fieldLabel: String) throws -> Int? {
        let field = try Self.field(for: fieldLabel)
        return Rules.player(at: field, in: state)?.rawValue
    }

    public func target(from fieldLabel: String) throws -> String? {
        let field = try Self.field(for: fieldLabel)
        return try Rules.target(from: field, in: state)?.description
    }

    public func movablePieces() -> Set<String> {
        Set(Rules.movablePieces(in: state).map(\.description))
    }

    public mutating func roll(_ n: Int) {
        state = Rules.roll(n, in: state)
    }

    public mutating func move(field fieldLabel: String) throws {
        let field = try Self.field(for: fieldLabel)
        state = try Rules.move(field: field, in: state)
    }

    private static func field(for fieldLabel: String) throws -> Field {
        guard let field = Field(fieldLabel) else {
            throw GameError(message: "Invalid field")
        }

        return field
    }
}

extension Game.Field: LosslessStringConvertible {

    var description: String {
        switch self {
        case .track(let field):
            String(format: "%02d", field.index)
        case .home(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        case .out(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        }
    }

    init?(_ description: String) {
        guard description.count == 2,
              let digit = description.first!.wholeNumberValue
        else { return nil }

        if let index = Int(description), let field = Game.Track.Field(index: index) {
            self = .track(field)
        }
        else if let field = Game.Home.Field(rawValue: String(description.last!)), let player = Game.Player(rawValue: digit) {
            self = .home(player, field)
        }
        else if let field = Game.Out.Field(rawValue: String(description.last!)), let player = Game.Player(rawValue: digit) {
            self = .out(player, field)
        }
        else {
            return nil
        }
    }
}
