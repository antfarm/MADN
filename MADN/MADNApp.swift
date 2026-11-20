import SwiftUI
import MADNCore

@main struct MADNApp: App {

    var body: some Scene {
        WindowGroup {
            GameView(game: Game.saved)
                .statusBarHidden()
        }
    }
}
