extension Game {

    enum Rules {

        static func initialState(player: Player = .one) -> State {
            let pieces = Dictionary(uniqueKeysWithValues:
                Player.allCases.flatMap { player in
                    Out.Field.allCases.map { field in (Field.out(player, field), player) }
                }
            )

            return try! State(pieces: pieces, player: player)
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

            if case .out = field {
                return die == .six ? owner.startField : nil // bring in
            }

            let steps = try owner.stepsTravelled(to: field)

            return owner.field(stepsTravelled: steps + die.rawValue) // ordinary move
        }

        static func canMove(from field: Field, in state: State) -> Bool {
            guard let owner = player(at: field, in: state) else { return false } // field is not empty
            guard let target = try? target(from: field, in: state) else { return false } // target field exists

            return player(at: target, in: state) != owner // target not occupied by another of the owner's pieces
        }

        static func movablePieces(in state: State) -> Set<Field> {
            pieces(for: state.player, in: state).filter { canMove(from: $0, in: state) }
        }

        static func roll(_ die: DieValue, in state: State) -> State {
            var next = state
            next.die = die
            return next
        }

        static func move(field: Field, in state: State) throws -> State {
            guard let die = state.die else { return state }

            var next = state

            if die != .six {
                next.player = state.player.next
            }

            next.die = nil
            return next
        }
    }
}
