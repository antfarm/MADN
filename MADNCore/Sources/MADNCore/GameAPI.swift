import Foundation

public struct GameAPI {

    var engine: Game

    public static func isValid(fields: Set<String>) -> Bool {
        fields == Set(Game.Field.allCases.map(\.description))
    }

    public init(pieces: [Set<String>], player: Int = 0) {
        engine = Game(pieces: Dictionary(uniqueKeysWithValues:
            zip(Game.Player.allCases, pieces).flatMap { player, fields in
                fields.map { (Game.Field($0)!, player) }
            }
        ), player: Game.Player(rawValue: player)!)
    }

    public var player: Int { engine.player.rawValue }

    public var die: Int? { engine.die }

    public func player(at field: String) -> Int? {
        guard let field = Game.Field(field) else { return nil }

        return engine.player(at: field)?.rawValue
    }

    public func movablePieces() -> Set<String> {
        Set(engine.movablePieces().map(\.description))
    }

    public mutating func roll(_ n: Int) {
        engine.roll(n)
    }

    public mutating func move(field: String) throws {
        guard let field = Game.Field(field) else { throw GameError(message: "Invalid field") }

        try engine.move(field: field)
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
