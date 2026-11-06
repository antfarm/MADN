extension Game {

    enum Rules {

        static func target(from field: Field, in state: State) throws -> Field? {
            guard let owner = state.board.player(at: field) else { throw GameError(message: "No piece on field") }
            guard let die = state.die else { throw GameError(message: "Die not rolled") }
            guard owner == state.player else { return nil } // current player's piece

            let target: Field?

            if field.isOut {
                target = die == .six ? owner.startField : nil // bring in
            } else {
                let steps = try owner.stepsTravelled(to: field)
                target = owner.field(stepsTravelled: steps + die.rawValue) // ordinary move
            }

            guard let target else { return nil } // target field exists

            guard state.board.player(at: target) != owner else { return nil } // target not occupied by another of the owner's pieces

            return target
        }

        static func movablePieces(in state: State) -> Set<Field> {
            state.board.pieces(for: state.player).filter { field in
                let canMove = (try? target(from: field, in: state)) != nil

                return canMove
            }
        }

        static func roll(_ die: DieValue, in state: State) throws -> State {
            guard state.die == nil else {
                throw GameError(message: "Die already rolled")
            }

            var next = state
            next.die = die
            return next
        }

        static func move(field: Field, in state: State) throws -> State {
            guard let target = try target(from: field, in: state) else {
                throw GameError(message: "\(field) cannot move")
            }

            var next = state
            try next.board.move(from: field, to: target)

            if state.die != .six {
                next.player = state.player.next
            }

            next.die = nil
            return next
        }
    }
}
