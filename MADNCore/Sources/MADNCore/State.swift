extension Game {

    struct State: Codable {
        var board: Board
        var player: Player
        var phase: Rules.Phase
        var finishedPlayers: [Player] = []

        var players: Set<Player> { board.players }

        var die: DieValue? {
            if case .moving(let die) = phase { die } else { nil }
        }

        var isStarted: Bool {
            if case .notStarted = phase { false } else { true }
        }

        var isOver: Bool {
            if case .over = phase { true } else { false }
        }

        var isPaused: Bool {
            if case .paused = phase { true } else { false }
        }

        init(players: Set<Player>, player: Player? = nil) throws {
            board = try Board(pieces: Rules.initialPieces(for: players))
            self.player = try Self.startingPlayer(player, on: board)
            phase = .notStarted
        }

        // for tests and previews
        init(pieces: PiecePositions, player: Player? = nil, die: DieValue? = nil) throws {
            board = try Board(pieces: pieces)
            self.player = try Self.startingPlayer(player, on: board)

            phase = if let die {
                .moving(die)
            }
            else {
                .rolling(triesLeft: 3)
            }

            finishedPlayers = Player.allCases.filter { player in
                players.contains(player) && Rules.hasPlayerFinished(player, in: self)
            }

            if Rules.isGameOver(in: self) {
                phase = .over
            }
            else if Rules.hasPlayerFinished(in: self) {
                phase = .paused
            }
            else if die == nil {
                phase = .rolling(triesLeft: Rules.triesForTurn(in: self))
            }
        }

        private static func startingPlayer(_ player: Player?, on board: Board) throws -> Player {
            guard let player = player ?? Player.allCases.first(where: board.players.contains),
                  board.players.contains(player)
            else {
                throw GameError.startingPlayerNotInGame
            }

            return player
        }
    }

    public enum Player: Int, CaseIterable, Sendable, Codable {
        case one, two, three, four

        var next: Player {
            Player.allCases[(rawValue + 1) % Player.allCases.count]
        }
    }

    public enum DieValue: Int, CaseIterable, Sendable, Codable {
        case one = 1, two, three, four, five, six

        public static func random() -> DieValue {
            allCases.randomElement()!
        }
    }
}
