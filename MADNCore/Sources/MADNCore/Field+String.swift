import Foundation

extension Game.Field: LosslessStringConvertible {

    var description: String {
        switch self {
        case .track(let field):
            String(format: "%02d", field.index)
        case .home(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        case .out(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        }
    }

    init?(_ description: String) {
        guard description.count == 2,
              let digit = description.first!.wholeNumberValue
        else { return nil }

        if let index = Int(description), let field = Game.Track.Field(index: index) {
            self = .track(field)
        }
        else if let field = Game.Home.Field(rawValue: String(description.last!)), let player = Game.Player(rawValue: digit) {
            self = .home(player, field)
        }
        else if let field = Game.Out.Field(rawValue: String(description.last!)), let player = Game.Player(rawValue: digit) {
            self = .out(player, field)
        }
        else {
            return nil
        }
    }
}
