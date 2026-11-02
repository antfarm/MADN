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

    func player(at field: Field) -> Player? {
        pieces[field]
    }

    func pieces(for player: Player) -> Set<Field> {
        Set(pieces.filter { $0.value == player }.keys)
    }

    func target(from field: Field) -> Field? {
        guard let owner = player(at: field), // field is not empty
              let die                       // die has been rolled
        else { return nil }

        return switch field {
        case .out(let player, _):
            die == 6 ? .track(Track.startField(for: player)) : nil // bring in
        default:
            field.advanced(by: die, for: owner) // ordinary move
        }
    }

    func canMove(from field: Field) -> Bool {
        guard let owner = player(at: field) else { return false } // field is not empty
        guard let target = target(from: field) else { return false } // target field exists

        return player(at: target) != owner // target not occupied by another of the owner's pieces
    }

    func movablePieces() -> Set<Field> {
        pieces(for: player).filter(canMove(from:))
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
}

public struct GameError: Error {
    public let message: String
}
