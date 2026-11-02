struct GameEngine {

    enum Player: Int, CaseIterable {
        case one, two, three, four

        var next: Player {
            Player.allCases[(rawValue + 1) % Player.allCases.count]
        }
    }

    typealias Pieces = [Field: Player]

    var player: Player = .one

    var die: Int? = nil

    var pieces: Pieces

    static let startPieces: Pieces = Dictionary(uniqueKeysWithValues:
        Player.allCases.flatMap { player in
            Out.Field.allCases.map { field in (Field.out(player, field), player) }
        }
    )

    init(pieces: Pieces = startPieces, player: Player = .one) {
        self.pieces = pieces
        self.player = player
    }

    func player(at field: Field) -> Player? {
        pieces[field]
    }

    func pieces(for player: Player) -> Set<Field> {
        Set(pieces.filter { $0.value == player }.keys)
    }

    func target(from field: Field) throws -> Field? {
        guard let owner = player(at: field) else { throw GameError(message: "No piece on field") }
        guard let die else { throw GameError(message: "Die not rolled") }

        return switch field {
        case .out(let player, _):
            die == 6 ? .track(Track.startField(for: player)) : nil // bring in
        default:
            try field.advanced(by: die, for: owner) // ordinary move
        }
    }

    func canMove(from field: Field) -> Bool {
        guard let owner = player(at: field) else { return false } // field is not empty
        guard let target = try? target(from: field) else { return false } // target field exists

        return player(at: target) != owner // target not occupied by another of the owner's pieces
    }

    func movablePieces() -> Set<Field> {
        pieces(for: player).filter(canMove(from:))
    }

    mutating func move(field: Field) throws {
        guard let die else { return }

        if die != 6 {
            player = player.next
        }

        self.die = nil
    }

    mutating func roll(_ n: Int) {
        die = n
    }

    enum Field: Hashable, CaseIterable {
        case track(Track.Field)
        case home(Player, Home.Field)
        case out(Player, Out.Field)

        static var allCases: [Field] {
            (0..<Track.length).map { .track(Track.Field(wrapping: $0)) }
            + Player.allCases.flatMap { player in Home.Field.allCases.map { .home(player, $0) } }
            + Player.allCases.flatMap { player in Out.Field.allCases.map { .out(player, $0) } }
        }

        func advanced(by steps: Int, for player: Player) throws -> Field? {
            switch self {
            case .track(let field):
                field.advanced(by: steps, for: player)
            case .home(let player, let field):
                field.advanced(by: steps, for: player)
            case .out:
                throw GameError(message: "Out field cannot advance")
            }
        }
    }

    enum Out {
        enum Field: String, CaseIterable {
            case A, B, C, D
        }
    }

    enum Track {
        static let length = 40

        static func startField(for player: Player) -> Field {
            Field(wrapping: player.rawValue * length / Player.allCases.count)
        }

        struct Field: Hashable {
            let index: Int

            init?(index: Int) {
                guard (0..<Track.length).contains(index) else { return nil }
                self.index = index
            }

            init(wrapping index: Int) {
                self.index = (index % Track.length + Track.length) % Track.length
            }

            func travelled(from start: Field) -> Int {
                (index - start.index + Track.length) % Track.length
            }

            func advanced(by steps: Int, for player: Player) -> GameEngine.Field? {
                let start = Track.startField(for: player)
                let travelled = travelled(from: start) + steps

                if let _ = Field(index: travelled) {
                   return .track(Field(wrapping: start.index + travelled))
                }

                if let target = Home.Field(index: travelled - Track.length) {
                    return .home(player, target)
                }

                return nil
            }
        }
    }

    enum Home {
        enum Field: String, CaseIterable {
            case a, b, c, d

            var index: Int {
                Field.allCases.firstIndex(of: self)!
            }

            init?(index: Int) {
                guard Field.allCases.indices.contains(index) else { return nil }
                self = Field.allCases[index]
            }

            func advanced(by steps: Int, for player: Player) -> GameEngine.Field? {
                guard let target = Field(index: index + steps) else { return nil }
                return .home(player, target)
            }
        }
    }
}

public struct GameError: Error {
    public let message: String
}
