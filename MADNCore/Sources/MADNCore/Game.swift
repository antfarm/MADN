import Foundation

public struct Game {

    var engine: GameEngine

    var state: GameEngine.State {
        get { engine.state }
        set { engine.state = newValue }
    }

    public static var allFields: Set<String> {
        Set(GameEngine.Field.allCases.map(\.description))
    }

    public init(pieces: [Set<String>]? = nil, player: Int = 0) {
        let player = GameEngine.Player(rawValue: player)!

        if let pieces {
            engine = GameEngine(pieces: Dictionary(uniqueKeysWithValues:
                zip(GameEngine.Player.allCases, pieces).flatMap { player, fields in
                    fields.map { (GameEngine.Field($0)!, player) }
                }
            ), player: player)
        } else {
            engine = GameEngine(player: player)
        }
    }

    public var player: Int { state.player.rawValue }

    public var die: Int? { state.die }

    public func player(at fieldLabel: String) throws -> Int? {
        let field = try field(for: fieldLabel)
        return engine.player(at: field)?.rawValue
    }

    public func target(from fieldLabel: String) throws -> String? {
        let field = try field(for: fieldLabel)
        return try engine.target(from: field)?.description
    }

    public func movablePieces() -> Set<String> {
        Set(engine.movablePieces().map(\.description))
    }

    public mutating func roll(_ n: Int) {
        engine.roll(n)
    }

    public mutating func move(field fieldLabel: String) throws {
        let field = try field(for: fieldLabel)
        try engine.move(field: field)
    }

    private func field(for fieldLabel: String) throws -> GameEngine.Field {
        guard let field = GameEngine.Field(fieldLabel) else {
            throw GameError(message: "Invalid field")
        }

        return field
    }
}

extension GameEngine.Field: LosslessStringConvertible {

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

        if let index = Int(description), let field = GameEngine.Track.Field(index: index) {
            self = .track(field)
        }
        else if let field = GameEngine.Home.Field(rawValue: String(description.last!)), let player = GameEngine.Player(rawValue: digit) {
            self = .home(player, field)
        }
        else if let field = GameEngine.Out.Field(rawValue: String(description.last!)), let player = GameEngine.Player(rawValue: digit) {
            self = .out(player, field)
        }
        else {
            return nil
        }
    }
}
