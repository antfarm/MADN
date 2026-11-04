public struct Game {

    var state: State

    public init(pieces: [Field: Player]? = nil, player: Player = .one) throws {
        state = try State(pieces: pieces, player: player)
    }

    public var player: Player { state.player }

    public var die: DieValue? { state.die }

    public func player(at field: Field) -> Player? {
        state.board.player(at: field)
    }

    public func target(from field: Field) throws -> Field? {
        try Rules.target(from: field, in: state)
    }

    public func movablePieces() -> Set<Field> {
        Rules.movablePieces(in: state)
    }

    public mutating func roll(_ die: DieValue = .random()) {
        state = Rules.roll(die, in: state)
    }

    public mutating func move(field: Field) throws {
        state = try Rules.move(field: field, in: state)
    }

    struct State {
        var board: Board
        var player: Player
        var die: DieValue? = nil

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

public struct GameError: Error {
    public let message: String
}
