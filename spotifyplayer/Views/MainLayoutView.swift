// rule.mdを読むこと
import SwiftUI

struct MainLayoutView: View {
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @State private var selectedPlaylist: Playlist?
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: playlistViewModel, selectedPlaylist: $selectedPlaylist)
                .navigationTitle("Spotify Player")
        } detail: {
            if let playlist = selectedPlaylist {
                PlaylistDetailView(playlist: playlist, viewModel: playlistViewModel)
            } else {
                Text("Select a playlist to start")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }
}
