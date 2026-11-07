extension Game {

    struct State {
        var board: Board
        var player: Player
        var die: DieValue? = nil
        var extraRolls = 0

        init(pieces: Pieces?, player: Player, die: DieValue? = nil) throws {
            self.board = try Board(pieces: pieces)
            self.player = player
            self.die = die
        }
    }

    typealias Pieces = [Field: Player]

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
