public struct Game {

    public enum Player: Int, CaseIterable, Sendable {
        case one, two, three, four

        var next: Player {
            Player.allCases[(rawValue + 1) % Player.allCases.count]
        }
    }

    typealias Pieces = [Field: Player]

    public var player: Player = .one

    public var die: Int? = nil

    var pieces: Pieces

    static let startPieces: Pieces = Dictionary(uniqueKeysWithValues:
        Player.allCases.flatMap { player in
            Out.Field.allCases.map { field in (Field.out(player, field), player) }
        }
    )

    init(pieces: Pieces = startPieces, player: Player = .one) {
        self.pieces = pieces
        self.player = player
    }

    func piece(at field: Field) -> Player? {
        pieces[field]
    }

    func movable() -> Set<Field> {
        let movable = pieces
            .filter { $0.value == player } // own pieces
            .keys
            .filter { field in
                guard let target = target(from: field) else { return false } // the target field exists
                return piece(at: target) != player // not occupied by own piece
            }

        return Set(movable)
    }

    func target(from field: Field) -> Field? {
        guard let die else { return nil }

        switch field {
        case .out(let player, _):
            return .track(Track.startField(for: player))

        case .track(let field):
            let start = Track.startField(for: player)
            let newTravelled = field.travelled(from: start) + die

            if let newField = Track.Field(travelled: newTravelled, from: start) {
                return .track(newField)
            }

            if let newField = Home.Field(travelled: newTravelled) {
                return .home(player, newField)
            }

            return nil

        case .home(let player, let field):
            if let newField = Home.Field(index: field.index + die) {
                return .home(player, newField)
            }

            return nil
        }
    }

    mutating func move(field: Field) throws {
        guard let die else { return }

        if die != 6 {
            player = player.next
        }

        self.die = nil
    }

    public mutating func roll(_ n: Int) {
        die = n
    }

    // public mutating func move(space: String) throws {
    //     guard movable.contains(space) else { throw GameError(message: "Invalid move") }
    //     guard let die else { return }

    //     if die != 6 {
    //         player = (player + 1) % 4
    //     }

    //     self.die = nil
    // }
}

public struct GameError: Error {
    public let message: String
}
