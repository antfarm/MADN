extension Game {

    struct State: Codable {
        var board: Board
        var player: Player
        var die: DieValue? = nil
        var extraRollsUsed = 0

        var players: Set<Player> { board.players }

        init(pieces: PiecePositions, player: Player, die: DieValue? = nil) throws {
            self.board = try Board(pieces: pieces)

            guard board.players.contains(player) else {
                throw GameError.startingPlayerNotInGame
            }

            self.player = player
            self.die = die
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
