struct GameEngine {

    enum Player: Int, CaseIterable {
        case one, two, three, four

        var next: Player {
            Player.allCases[(rawValue + 1) % Player.allCases.count]
        }
    }

    typealias Pieces = [Field: Player]

    struct State {
        static let startPieces: Pieces = Dictionary(uniqueKeysWithValues:
            Player.allCases.flatMap { player in
                Out.Field.allCases.map { field in (Field.out(player, field), player) }
            }
        )

        var pieces = startPieces
        var player = Player.one
        var die: Int? = nil
    }

    var state: State

    init(pieces: Pieces = State.startPieces, player: Player = .one) {
        state = State(pieces: pieces, player: player)
    }

    func player(at field: Field) -> Player? {
        state.pieces[field]
    }

    func pieces(for player: Player) -> Set<Field> {
        Set(state.pieces.filter { $0.value == player }.keys)
    }

    func target(from field: Field) throws -> Field? {
        guard let owner = player(at: field) else { throw GameError(message: "No piece on field") }
        guard let die = state.die else { throw GameError(message: "Die not rolled") }

        return switch field {
        case .out(let player, _):
            die == 6 ? .track(Track.startField(for: player)) : nil // bring in
        default:
            try field.advanced(by: die, for: owner) // ordinary move
        }
    }

    func canMove(from field: Field) -> Bool {
        guard let owner = player(at: field) else { return false } // field is not empty
        guard let target = try? target(from: field) else { return false } // target field exists

        return player(at: target) != owner // target not occupied by another of the owner's pieces
    }

    func movablePieces() -> Set<Field> {
        pieces(for: state.player).filter(canMove(from:))
    }

    mutating func move(field: Field) throws {
        guard let die = state.die else { return }

        if die != 6 {
            state.player = state.player.next
        }

        state.die = nil
    }

    mutating func roll(_ n: Int) {
        state.die = n
    }
}

public struct GameError: Error {
    public let message: String
}
