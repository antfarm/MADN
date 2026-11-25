extension Game {

    typealias Move = (from: Field, to: Field)

    public enum Action: Equatable {
        case roll(DieValue)
        case move(from: Field, to: Field)
        case resume
    }

    enum Rules {

        enum Phase: Codable {
            case rolling(triesLeft: Int)
            case moving(DieValue)
            case finished
            case over
        }

        static func initialPieces(for players: Set<Player>) throws -> PiecePositions {
            guard players.count >= 2 else {
                throw GameError.tooFewPlayers
            }

            return Dictionary(uniqueKeysWithValues: players.map { ($0, Set($0.outFields)) })
        }

        static func activePlayers(in state: State) -> Set<Player> {
            state.players.subtracting(finishedPlayers(in: state))
        }

        static func finishedPlayers(in state: State) -> [Player] {
            state.finishedPlayers
        }

        static func hasFinished(player: Player, in state: State) -> Bool {
            state.board.pieces(for: player) == Set(player.homeFields)
        }

        static func isGameOver(in state: State) -> Bool {
            activePlayers(in: state).isEmpty
        }

        static func hasPlayerFinished(in state: State) -> Bool {
            finishedPlayers(in: state).contains(state.player)
        }

        private static func possibleMoves(with die: DieValue, in state: State) -> [Move] {
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

        static func actions(in state: State) -> [Action] {
            switch state.phase {
            case .rolling:
                DieValue.allCases.map(Action.roll)
            case .moving(let die):
                possibleMoves(with: die, in: state).map { move in
                    .move(from: move.from, to: move.to)
                }
            case .finished:
                [.resume]
            case .over:
                []
            }
        }

        static func target(from field: Field, in state: State) -> Field? {
            for case .move(field, let target) in actions(in: state) {
                return target
            }

            return nil
        }

        static func apply(_ action: Action, in state: State) throws -> State {
            guard actions(in: state).contains(action) else {
                throw GameError.actionNotOffered
            }

            return switch (state.phase, action) {
            case (.rolling(let triesLeft), .roll(let die)):
                roll(die, triesLeft: triesLeft, in: state)
            case (.moving(let die), .move(let from, let to)):
                try move(from: from, to: to, with: die, in: state)
            case (.finished, .resume):
                resume(in: state)
            default:
                throw GameError.actionNotOffered
            }
        }

        private static func roll(_ die: DieValue, triesLeft: Int, in state: State) -> State {
            var state = state
            let pieces = state.board.pieces(for: state.player)

            if !possibleMoves(with: die, in: state).isEmpty {
                state.phase = .moving(die)
            }
            else if triesLeft > 1 // three rolls not used up
                && pieces.contains(where: \.isOut) // staged pieces left
                && !hasPieceInPlay(in: state) { // nothing else could move

                state.phase = .rolling(triesLeft: triesLeft - 1) // roll again
            }
            else {
                advanceTurn(after: die, in: &state)
            }

            return state
        }

        private static func move(from field: Field, to target: Field, with die: DieValue, in state: State) throws -> State {
            var state = state

            if let opponent = state.board.player(at: target) {
                let outField = opponent.outFields.first(where: state.board.isEmpty)!
                try state.board.move(from: target, to: outField)
            }

            try state.board.move(from: field, to: target)

            if hasFinished(player: state.player, in: state) {
                state.finishedPlayers.append(state.player)
            }

            if isGameOver(in: state) {
                state.phase = .over
            }
            else if hasPlayerFinished(in: state) {
                state.phase = .finished
            }
            else {
                advanceTurn(after: die, in: &state)
            }

            return state
        }

        private static func resume(in state: State) -> State {
            var state = state
            advanceTurn(after: nil, in: &state)
            return state
        }

        private static func hasPieceInPlay(in state: State) -> Bool {
            let pieces = state.board.pieces(for: state.player)
            let homePieces = pieces.filter(\.isHome)

            return pieces.contains(where: \.isTrack) // some on the track
                || homePieces != Set(state.player.homeFields.suffix(homePieces.count)) // some in the home row can still move
        }

        private static func advanceTurn(after die: DieValue?, in state: inout State) {
            let shouldRollAgain = die == .six && activePlayers(in: state).contains(state.player)

            state.phase = .rolling(triesLeft: 3)

            if shouldRollAgain || isGameOver(in: state) { return }

            let nextPlayer = state.player.next
            state.player = [nextPlayer, nextPlayer.next, nextPlayer.next.next, state.player]
                .first(where: activePlayers(in: state).contains)!
        }
    }
}
