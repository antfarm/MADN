import Foundation
import MADNCore

extension Game {

    private static let key = "game"

    static var saved: Game? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Game.self, from: data)
    }

    func save() {
        let data = try? JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    static func deleteSaved() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
