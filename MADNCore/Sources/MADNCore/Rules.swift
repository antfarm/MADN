extension Game {

    typealias Move = (from: Field, to: Field)

    public enum Action: Equatable {
        case roll(DieValue)
        case move(from: Field, to: Field)
    }

    enum Rules {

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

        static func hasPlayerFinished(in state: State) -> Bool {
            hasPlayerFinished(state.player, in: state)
        }

        static func hasPlayerFinished(_ player: Player, in state: State) -> Bool {
            let pieces = state.board.pieces(for: player)

            return pieces == Set(player.homeFields.suffix(pieces.count))
        }

        static func isGameOver(in state: State) -> Bool {
            activePlayers(in: state).isEmpty
        }

        enum Phase: Codable {
            case notStarted
            case rolling(triesLeft: Int)
            case moving(DieValue)
            case paused
            case over
        }


        static func actions(in state: State) -> [Action] {
            switch state.phase {
            case .notStarted:
                []
            case .rolling:
                DieValue.allCases.map(Action.roll)
            case .moving(let die):
                possibleMoves(with: die, in: state).map { move in
                    .move(from: move.from, to: move.to)
                }
            case .paused, .over:
                []
            }
        }

        static func apply(_ action: Action, to state: inout State) throws {
            guard actions(in: state).contains(action) else {
                throw GameError.actionNotOffered
            }

            switch (state.phase, action) {
            case (.rolling, .roll(let die)) where !possibleMoves(with: die, in: state).isEmpty:
                state.phase = .moving(die)

            case (.rolling(let triesLeft), .roll) where triesLeft > 1:
                state.phase = .rolling(triesLeft: triesLeft - 1)

            case (.rolling, .roll(.six)):
                state.phase = .rolling(triesLeft: triesForTurn(in: state))

            case (.rolling, .roll):
                advanceTurn(in: &state)

            case (.moving(let die), .move(let from, let to)):
                move(from, to, in: &state)

                switch die {
                case _ where isGameOver(in: state):
                    state.phase = .over

                case _ where hasPlayerFinished(in: state):
                    state.phase = .paused

                case .six:
                    state.phase = .rolling(triesLeft: triesForTurn(in: state))

                default:
                    advanceTurn(in: &state)
                }

            default:
                throw GameError.actionNotOffered
            }
        }

        private static func move(_ field: Field, _ target: Field, in state: inout State) {
            if let opponent = state.board.player(at: target) {
                let outField = opponent.outFields.first(where: state.board.isEmpty)!
                try! state.board.move(from: target, to: outField)
            }

            try! state.board.move(from: field, to: target)

            if hasPlayerFinished(in: state) {
                state.finishedPlayers.append(state.player)
            }
        }

        private static func advanceTurn(in state: inout State) {
            let nextPlayer = state.player.next
            state.player = [nextPlayer, nextPlayer.next, nextPlayer.next.next, state.player]
                .first(where: activePlayers(in: state).contains)!

            state.phase = .rolling(triesLeft: triesForTurn(in: state))
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

        static func triesForTurn(in state: State) -> Int {
            assert(!hasPlayerFinished(in: state), "a finished player gets no turn")

            let pieces = state.board.pieces(for: state.player)
            let homePieces = pieces.filter(\.isHome)

            let hasPieceInPlay = pieces.contains(where: \.isTrack) // some on the track
                || homePieces != Set(state.player.homeFields.suffix(homePieces.count)) // some in the home row can still move

            return hasPieceInPlay ? 1 : 3
        }

        static func start(in state: State) throws -> State {
            guard case .notStarted = state.phase else {
                throw GameError.alreadyStarted
            }

            var state = state
            state.phase = .rolling(triesLeft: triesForTurn(in: state))
            return state
        }

        static func resume(in state: State) throws -> State {
            guard case .paused = state.phase else {
                throw GameError.notPaused
            }

            var state = state
            advanceTurn(in: &state)
            return state
        }

        static func end(in state: State) -> State {
            var state = state
            state.phase = .over
            return state
        }
    }
}
