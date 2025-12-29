// rule.mdを読むこと
import SwiftUI

// サイドバーの選択項目を管理
enum SidebarItem: Hashable {
    case search
    case playlist(Playlist)
}

struct MainLayoutView: View {
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @EnvironmentObject var playerViewModel: PlayerViewModel // App側から共有される
    @State private var selection: SidebarItem? = .search // 初期表示は検索
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(selection: $selection) {
                    SidebarContent(playlistViewModel: playlistViewModel)
                }
                .listStyle(.sidebar)
                .frame(minWidth: 250)
                .navigationTitle("Spotify Player")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            playlistViewModel.refreshPlaylists()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Refresh Playlists")
                    }
                }
                
            } detail: {
                NavigationStack {
                    if let selection = selection {
                        switch selection {
                        case .search:
                            SearchView()
                        case .playlist(let playlist):
                            PlaylistDetailView(playlist: playlist, viewModel: playlistViewModel)
                        }
                    }
                    else {
                        Text("Select an item")
                            .foregroundColor(.secondary)
                    }
                }
                .environmentObject(playlistViewModel)
                // playerViewModelは上位から流れてくるのでここでは明示的に渡さなくても良いが、
                // NavigationStackの挙動によっては切れることがあるため、必要なら残す。
                // 今回は念のため残すが、自分自身のプロパティを使う。
                .environmentObject(playerViewModel) 
            }
            
            PlayerBarView(viewModel: playerViewModel)
        }
    }
}

struct SidebarContent: View {
    @ObservedObject var playlistViewModel: PlaylistViewModel
    
    var body: some View {
        Section {
            NavigationLink(value: SidebarItem.search) {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
        header: {
            Text("Discover")
        }
        
        Section {
            ForEach(playlistViewModel.playlists) { playlist in
                NavigationLink(value: SidebarItem.playlist(playlist)) {
                    HStack(spacing: 12) {
                        AsyncImage(url: playlist.imageURL) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                        
                        Text(playlist.name)
                            .font(.body)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        header: {
            Text("Library")
        }
    }
}
