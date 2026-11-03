extension Game {

    typealias Pieces = [Field: Player]

    struct State {
        var pieces: Pieces
        var player: Player
        var die: Int? = nil

        init(pieces: Pieces, player: Player, die: Int? = nil) throws {
            for (field, piecePlayer) in pieces {
                switch field {
                case .home(let owner, _), .out(let owner, _):
                    guard owner == piecePlayer else {
                        throw GameError(message: "Player \(piecePlayer.rawValue) cannot be on \(field)")
                    }
                case .track:
                    break
                }
            }

            for seat in Player.allCases {
                guard pieces.values.filter({ $0 == seat }).count <= Out.Field.allCases.count else {
                    throw GameError(message: "Player \(seat.rawValue) has too many pieces")
                }
            }

            self.pieces = pieces
            self.player = player
            self.die = die
        }
    }

    enum Rules {

        static let startPieces: Pieces = Dictionary(uniqueKeysWithValues:
            Player.allCases.flatMap { player in
                Out.Field.allCases.map { field in (Field.out(player, field), player) }
            }
        )

        static func initialState(player: Player = .one) -> State {
            try! State(pieces: startPieces, player: player)
        }

        static func player(at field: Field, in state: State) -> Player? {
            state.pieces[field]
        }

        static func pieces(for player: Player, in state: State) -> Set<Field> {
            Set(state.pieces.filter { $0.value == player }.keys)
        }

        static func target(from field: Field, in state: State) throws -> Field? {
            guard let owner = player(at: field, in: state) else { throw GameError(message: "No piece on field") }
            guard let die = state.die else { throw GameError(message: "Die not rolled") }

            return switch field {
            case .out(let player, _):
                die == 6 ? .track(Track.startField(for: player)) : nil // bring in
            default:
                try field.advanced(by: die, for: owner) // ordinary move
            }
        }

        static func canMove(from field: Field, in state: State) -> Bool {
            guard let owner = player(at: field, in: state) else { return false } // field is not empty
            guard let target = try? target(from: field, in: state) else { return false } // target field exists

            return player(at: target, in: state) != owner // target not occupied by another of the owner's pieces
        }

        static func movablePieces(in state: State) -> Set<Field> {
            pieces(for: state.player, in: state).filter { canMove(from: $0, in: state) }
        }

        static func roll(_ n: Int, in state: State) -> State {
            var next = state
            next.die = n
            return next
        }

        static func move(field: Field, in state: State) throws -> State {
            guard let die = state.die else { return state }

            var next = state

            if die != 6 {
                next.player = state.player.next
            }

            next.die = nil
            return next
        }
    }
}

public struct GameError: Error {
    public let message: String
}
