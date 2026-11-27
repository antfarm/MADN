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

        private enum Command {
            case start
            case resume
            case end

            case action(Action)
        }

        static func start(in state: State) throws -> State {
            var state = state
            try apply(.start, to: &state)
            return state
        }

        static func resume(in state: State) throws -> State {
            var state = state
            try apply(.resume, to: &state)
            return state
        }

        static func end(in state: State) -> State {
            var state = state
            try! apply(.end, to: &state)
            return state
        }

        static func apply(_ action: Action, to state: inout State) throws {
            try apply(.action(action), to: &state)
        }

        private static func apply(_ command: Command, to state: inout State) throws {
            if case .action(let action) = command, !actions(in: state).contains(action) {
                throw GameError.actionNotOffered
            }

            switch (state.phase, command) {

            // Game commands

            case (.notStarted, .start):
                state.phase = .rolling(triesLeft: triesForTurn(in: state))

            case (_, .start):
                throw GameError.alreadyStarted


            case (.paused, .resume):
                advanceTurn(in: &state)
                state.phase = .rolling(triesLeft: triesForTurn(in: state))

            case (_, .resume):
                throw GameError.notPaused

            case (_, .end):
                state.phase = .over

            // Player actions

            case (.rolling, .action(.roll(let die))) where !possibleMoves(with: die, in: state).isEmpty:
                state.phase = .moving(die)

            case (.rolling(let triesLeft), .action(.roll)) where triesLeft > 1:
                state.phase = .rolling(triesLeft: triesLeft - 1)

            case (.rolling, .action(.roll(.six))):
                state.phase = .rolling(triesLeft: triesForTurn(in: state))

            case (.rolling, .action(.roll)):
                advanceTurn(in: &state)
                state.phase = .rolling(triesLeft: triesForTurn(in: state))

            case (.moving(let die), .action(.move(let from, let to))):
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
                    state.phase = .rolling(triesLeft: triesForTurn(in: state))

                }

            case (_, .action):
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
        }

        private static func possibleMoves(with die: DieValue, in state: State) -> [Move] {
            let pieces = state.board.pieces(for: state.player)

            // Moves that bring a piece in with a 6...

            let outPieces = pieces.filter(\.isOut)

            let bringInMoves: [Move] = die == .six
                ? outPieces.map { (from: $0, to: state.player.startField) }
                : []

            // Moves on the track...

            let trackPieces = pieces.subtracting(outPieces)
            let path = state.player.path

            let trackMoves: [Move] = trackPieces
                .map { try! state.player.stepsTravelled(to: $0) }
                // not moving past the last field in the home row
                .filter { steps in steps + die.rawValue < path.count }
                // not passing a piece in the home row
                .filter { steps in
                    path[steps + 1 ..< steps + die.rawValue]
                        .filter(\.isHome)
                        .allSatisfy(state.board.isEmpty)
                }
                .map { steps in (from: path[steps], to: path[steps + die.rawValue]) }

            // ...that would not land on one of the player's own pieces

            let possibleMoves = (bringInMoves + trackMoves)
                .filter { state.board.player(at: $0.to) != state.player }

            // Mandatory moves

            let mandatoryMoves = MandatoryMoveCondition.allCases.lazy
                .map { condition in
                    possibleMoves.filter { condition.applies(to: $0, in: state) }
                }
                .first { !$0.isEmpty }

            return mandatoryMoves ?? possibleMoves
        }

        private enum MandatoryMoveCondition: CaseIterable {
            case bringingIn
            case clearingStart
            case capturing

            func applies(to move: Move, in state: State) -> Bool {
                switch self {
                case .bringingIn: move.from.isOut

                case .clearingStart:
                    state.board.pieces(for: state.player).contains(where: \.isOut)
                        && move.from == state.player.startField

                case .capturing: !state.board.isEmpty(move.to)
                }
            }
        }

        static func triesForTurn(in state: State) -> Int {
            assert(!hasPlayerFinished(in: state), "a finished player gets no turn")

            let pieces = state.board.pieces(for: state.player)
            let homePieces = pieces.filter(\.isHome)

            let hasPieceInPlay = pieces.contains(where: \.isTrack) // some on the track
                || homePieces != Set(state.player.homeFields.suffix(homePieces.count)) // some in the home row can still move

            return hasPieceInPlay ? 1 : 3
        }
    }
}
