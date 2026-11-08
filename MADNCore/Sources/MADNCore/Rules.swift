extension Game {

    typealias Move = (from: Field, to: Field)

    enum Rules {

        static func initialPieces(for players: Set<Player>) throws -> PiecePositions {
            guard players.count >= 2 else {
                throw GameError(message: "A game needs at least 2 players")
            }

            return Dictionary(uniqueKeysWithValues: players.map { ($0, Set($0.outFields)) })
        }

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
                        .allSatisfy(state.board.isEmpty)
                    else { return nil }

                    return (from: field, to: target)
                }
            }
            .filter { state.board.player(at: $0.to) != state.player } // target not occupied by an own piece

            let pieces = state.board.pieces(for: state.player)

            if pieces.contains(where: \.isOut) {
                let bringInMoves = moves.filter { $0.from.isOut }
                guard bringInMoves.isEmpty else { return bringInMoves } // bringing in a piece comes first

                let leaveStartMoves = moves.filter { $0.from == state.player.startField }
                guard leaveStartMoves.isEmpty else { return leaveStartMoves } // clearing the start field comes next
            }

            let captureMoves = moves.filter { !state.board.isEmpty($0.to) }
            guard captureMoves.isEmpty else { return captureMoves } // capturing comes next

            return moves
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
                let outField = opponent.outFields.first(where: state.board.isEmpty)!
                try next.board.move(from: target, to: outField)
            }

            try next.board.move(from: field, to: target)

            advanceTurn(in: &next)
            return next
        }

        static func pass(in state: State) throws -> State {
            guard try possibleMoves(in: state).isEmpty else {
                throw GameError(message: "A move is possible")
            }

            var next = state

            let pieces = state.board.pieces(for: state.player)

            if state.extraRolls < 2 // extra rolls not used up (3 tries in total)
                && pieces.contains(where: \.isOut) // some pieces staged
                && !pieces.contains(where: \.isTrack) { // none on the track

                let homePieces = pieces.filter(\.isHome)

                if homePieces == Set(state.player.homeFields.suffix(homePieces.count)) { // packed at the end of the home row
                    next.extraRolls += 1
                    next.die = nil // roll again
                    return next
                }
            }

            advanceTurn(in: &next)
            return next
        }

        private static func advanceTurn(in state: inout State) {
            if state.die != .six {
                state.player = state.player.next
            }

            state.die = nil
            state.extraRolls = 0
        }
    }
}
