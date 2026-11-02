import Foundation

extension Game {

    public static func isValid(fields: Set<String>) -> Bool {
        fields == Set(Field.allCases.map(\.description))
    }

    public init(pieces: [Set<String>], player: Player = .one) {
        self.init(pieces: Dictionary(uniqueKeysWithValues:
            zip(Player.allCases, pieces).flatMap { player, fields in
                fields.map { (Field($0)!, player) }
            }
        ), player: player)
    }

    public func player(at field: String) -> Int? {
        guard let field = Field(field) else { return nil }

        return player(at: field)?.rawValue
    }

    public func movablePieces() -> Set<String> {
        let movable: Set<Field> = movablePieces()

        return Set(movable.map(\.description))
    }

    public mutating func move(field: String) throws {
        guard let field = Field(field) else { throw GameError(message: "Invalid field") }

        try move(field: field)
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
