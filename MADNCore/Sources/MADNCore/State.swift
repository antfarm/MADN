extension Game {

    struct State: Codable {
        var board: Board
        let players: Set<Player>
        var player: Player
        var die: DieValue? = nil
        var extraRollsUsed = 0

        init(pieces: PiecePositions, player: Player, die: DieValue? = nil) throws {
            guard pieces[player] != nil else {
                throw GameError.startingPlayerNotInGame
            }

            self.board = try Board(pieces: pieces)
            self.players = Set(pieces.keys)
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
