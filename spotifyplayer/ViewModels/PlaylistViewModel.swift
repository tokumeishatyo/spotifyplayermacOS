// rule.mdを読むこと
import Foundation
import Combine

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var selectedPlaylist: Playlist?
    
    init() {
        // UI構築用のダミーデータ
        self.playlists = [
            Playlist(id: "1", name: "My Favorite Songs", description: "All time favorites", tracks: []),
            Playlist(id: "2", name: "Coding Lo-Fi", description: "Focus music", tracks: []),
            Playlist(id: "3", name: "Workout Mix", description: "High energy", tracks: [])
        ]
    }
}
