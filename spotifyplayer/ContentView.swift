// rule.mdを読むこと
import SwiftUI

struct ContentView: View {
    @StateObject private var authService = SpotifyAuthService.shared
    
    var body: some View {
        Group {
            if authService.accessToken != nil {
                MainLayoutView()
            } else {
                LoginView(authService: authService)
            }
        }
        .frame(minWidth: 800, minHeight: 600) // デスクトップアプリらしい最小サイズ
    }
}

// ログイン画面をサブビューとして切り出し
struct LoginView: View {
    @ObservedObject var authService: SpotifyAuthService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.house")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            
            Text("Spotify Player")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button(action: {
                authService.authorize()
            }) {
                if authService.isAuthorizing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Login with Spotify")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(authService.isAuthorizing)
        }
        .padding()
    }
}
