extension Game {

    struct State: Codable {
        var board: Board
        var player: Player
        var phase: Rules.Phase

        var players: Set<Player> { board.players }

        var die: DieValue? {
            switch phase {
            case .moving(let die): die
            case .finished(let die): die
            case .over(let die): die
            default: nil
            }
        }

        init(pieces: PiecePositions, player: Player, die: DieValue? = nil) throws {
            board = try Board(pieces: pieces)

            guard board.players.contains(player) else {
                throw GameError.startingPlayerNotInGame
            }

            self.player = player
            phase = if let die { .moving(die) } else { .rolling(triesLeft: 3) }

            if Rules.isGameOver(in: self) {
                phase = .over(die)
            }
            else if Rules.hasPlayerFinished(in: self) {
                phase = .finished(die)
            }
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
