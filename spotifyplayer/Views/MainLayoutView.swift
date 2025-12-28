// rule.mdを読むこと
import SwiftUI

// サイドバーの選択項目を管理
enum SidebarItem: Hashable {
    case search
    case playlist(Playlist)
}

struct MainLayoutView: View {
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @State private var selection: SidebarItem? = .search // 初期表示は検索
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    NavigationLink(value: SidebarItem.search) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                } header: {
                    Text("Discover")
                }
                
                Section(header: Text("Library")) {
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
            }
            .listStyle(.sidebar)
            .frame(minWidth: 250)
            .navigationTitle("Spotify Player")
            
        } detail: {
            NavigationStack {
                if let selection = selection {
                    switch selection {
                    case .search:
                        SearchView()
                            .environmentObject(playlistViewModel) // 追加用プレイリスト情報共有
                    case .playlist(let playlist):
                        PlaylistDetailView(playlist: playlist, viewModel: playlistViewModel)
                    }
                } else {
                    Text("Select an item")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
