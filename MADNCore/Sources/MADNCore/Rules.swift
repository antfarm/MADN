extension Game {

    typealias Move = (from: Field, to: Field)

    enum Rules {

        static func possibleMoves(in state: State) throws -> [Move] {
            guard let die = state.die else { throw GameError(message: "Die not rolled") }

            let moves: [Move] = state.board.pieces(for: state.player).compactMap { field in
                if field.isOut {
                    guard die == .six else { return nil } // bring in only with a 6

                    return (from: field, to: state.player.startField)
                }
                else {
                    guard let steps = try? state.player.stepsTravelled(to: field), // move not possible
                          let target = state.player.field(stepsTravelled: steps + die.rawValue) // past the home row
                    else { return nil }

                    guard (steps + 1 ..< steps + die.rawValue) // passing a piece in the home row
                        .compactMap(state.player.field(stepsTravelled:))
                        .filter(\.isHome)
                        .allSatisfy({ state.board.player(at: $0) == nil })
                    else { return nil }

                    return (from: field, to: target)
                }
            }

            return moves.filter { state.board.player(at: $0.to) != state.player } // target not occupied by an own piece
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
            guard let target = try possibleMoves(in: state).first(where: { $0.from == field })?.to else {
                throw GameError(message: "\(field) cannot move")
            }

            var next = state

            if let opponent = state.board.player(at: target) {
                let outField = opponent.outFields.first { state.board.player(at: $0) == nil }!
                try next.board.move(from: target, to: outField)
            }

            try next.board.move(from: field, to: target)

            if state.die != .six {
                next.player = state.player.next
            }

            next.die = nil
            return next
        }
    }
}
