// rule.mdを読むこと
import SwiftUI

@main
struct spotifyplayerApp: App {
    // ViewModelをAppレベルで保持し、ウィンドウ間で共有する
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(playerViewModel)
        }
        
        // ミニプレイヤー用ウィンドウ
        Window("Mini Player", id: MiniPlayerView.windowID) {
            MiniPlayerView(viewModel: playerViewModel)
                .frame(width: 250, height: 350)
        }
        .windowStyle(.hiddenTitleBar) // タイトルバーを隠してコンパクトに
        .windowResizability(.contentSize) // サイズ固定
    }
}
