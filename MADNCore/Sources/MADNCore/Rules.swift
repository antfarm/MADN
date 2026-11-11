extension Game {

    typealias Move = (from: Field, to: Field)

    enum Rules {

        static func initialPieces(for players: Set<Player>) throws -> PiecePositions {
            guard players.count >= 2 else {
                throw GameError.tooFewPlayers
            }

            return Dictionary(uniqueKeysWithValues: players.map { ($0, Set($0.outFields)) })
        }

        static func activePlayers(in state: State) -> Set<Player> {
            state.players.filter { state.board.pieces(for: $0) != Set($0.homeFields) }
        }

        static func isGameOver(in state: State) -> Bool {
            activePlayers(in: state).isEmpty
        }

        static func possibleMoves(in state: State) throws -> [Move] {
            guard let die = state.die else { throw GameError.dieNotRolled }

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
            guard !isGameOver(in: state) else {
                throw GameError.gameOver
            }

            guard state.die == nil else {
                throw GameError.dieAlreadyRolled
            }

            var state = state
            state.die = die
            return state
        }

        static func move(field: Field, in state: State) throws -> State {
            guard let target = try possibleMoves(in: state).first(where: { $0.from == field })?.to else {
                throw GameError.cannotMove(field)
            }

            var state = state

            if let opponent = state.board.player(at: target) {
                let outField = opponent.outFields.first(where: state.board.isEmpty)!
                try state.board.move(from: target, to: outField)
            }

            try state.board.move(from: field, to: target)

            advanceTurn(in: &state)
            return state
        }

        static func pass(in state: State) throws -> State {
            guard try possibleMoves(in: state).isEmpty else {
                throw GameError.movePossible
            }

            var state = state

            let pieces = state.board.pieces(for: state.player)

            if state.extraRollsUsed < 2 // three rolls not used up
                && pieces.contains(where: \.isOut) // staged pieces left
                && !hasPieceInPlay(in: state) { // nothing else could move

                state.extraRollsUsed += 1
                state.die = nil // roll again
                return state
            }

            advanceTurn(in: &state)
            return state
        }

        private static func hasPieceInPlay(in state: State) -> Bool {
            let pieces = state.board.pieces(for: state.player)
            let homePieces = pieces.filter(\.isHome)

            return pieces.contains(where: \.isTrack) // some on the track
                || homePieces != Set(state.player.homeFields.suffix(homePieces.count)) // some in the home row can still move
        }

        private static func advanceTurn(in state: inout State) {
            let shouldRollAgain = state.die == .six && activePlayers(in: state).contains(state.player)

            state.die = nil
            state.extraRollsUsed = 0

            if shouldRollAgain { return }

            let nextPlayer = state.player.next

            state.player = [nextPlayer, nextPlayer.next, nextPlayer.next.next]
                .first(where: activePlayers(in: state).contains) ?? state.player
        }
    }
}
