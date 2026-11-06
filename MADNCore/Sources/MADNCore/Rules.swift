extension Game {

    enum Rules {

        static func target(from field: Field, in state: State) throws -> Field? {
            guard let owner = state.board.player(at: field) else { throw GameError(message: "No piece on field") }
            guard let die = state.die else { throw GameError(message: "Die not rolled") }

            if field.isOut {
                return die == .six ? owner.startField : nil // bring in
            }

            let steps = try owner.stepsTravelled(to: field)

            return owner.field(stepsTravelled: steps + die.rawValue) // ordinary move
        }

        static func canMove(from field: Field, in state: State) -> Bool {
            guard let owner = state.board.player(at: field) else { return false } // field is not empty
            guard let target = try? target(from: field, in: state) else { return false } // target field exists

            return state.board.player(at: target) != owner // target not occupied by another of the owner's pieces
        }

        static func movablePieces(in state: State) -> Set<Field> {
            state.board.pieces(for: state.player).filter { canMove(from: $0, in: state) }
        }

        static func roll(_ die: DieValue, in state: State) -> State {
            var next = state
            next.die = die
            return next
        }

        static func move(field: Field, in state: State) throws -> State {
            guard let die = state.die else { return state }

            var next = state

            if let target = try target(from: field, in: state) {
                try next.board.move(from: field, to: target)
            }

            if die != .six {
                next.player = state.player.next
            }

            next.die = nil
            return next
        }
    }
}
