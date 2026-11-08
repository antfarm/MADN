extension Game {

    struct State {
        var board: Board
        let players: Set<Player>
        var player: Player
        var die: DieValue? = nil
        var extraRolls = 0

        init(pieces: PiecePositions, player: Player, die: DieValue? = nil) throws {
            guard pieces[player] != nil else {
                throw GameError(message: "Starting player must be one of the players")
            }

            self.board = try Board(pieces: pieces)
            self.players = Set(pieces.keys)
            self.player = player
            self.die = die
        }
    }

    public enum Player: Int, CaseIterable, Sendable {
        case one, two, three, four

        var next: Player {
            Player.allCases[(rawValue + 1) % Player.allCases.count]
        }
    }

    public enum DieValue: Int, CaseIterable, Sendable {
        case one = 1, two, three, four, five, six

        public static func random() -> DieValue {
            allCases.randomElement()!
        }
    }
}
