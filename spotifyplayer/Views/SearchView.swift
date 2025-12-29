// rule.mdを読むこと
import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showAddToPlaylistDialog = false
    
    // プレイリスト追加用
    @EnvironmentObject var playlistViewModel: PlaylistViewModel
    @State private var targetPlaylist: Playlist?
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索ヘッダー
            VStack(spacing: 12) {
                HStack {
                    // カテゴリ選択
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(SearchCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                    
                    Spacer()
                }
                
                HStack {
                    // キーワード入力
                    TextField("Search...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            viewModel.performSearch()
                        }
                    
                    // 件数選択
                    Picker("Limit", selection: $viewModel.searchLimit) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                    
                    Button("Search") {
                        viewModel.performSearch()
                    }
                    .keyboardShortcut(.defaultAction)
                    
                    Button("Clear") {
                        viewModel.clearAll()
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // アクションバー（編集モード、追加ボタン）
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        viewModel.isEditing.toggle()
                    }
                }) {
                    Text(viewModel.isEditing ? "完了" : "編集")
                }
                
                Button(action: {
                    showAddToPlaylistDialog = true
                }) {
                    Label("プレイリストに追加", systemImage: "plus.circle")
                }
                .disabled(!viewModel.isEditing || viewModel.selectedTrackIDs.isEmpty)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // 結果リスト
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.searchResults.isEmpty {
                Spacer()
                Text("Start searching to see results")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                // 結果の種類に応じて分岐
                if case .album = viewModel.searchResults.first {
                    // アルバム表示（グリッド）
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                            ForEach(viewModel.searchResults) { item in
                                if case .album(let album) = item {
                                    NavigationLink(destination: AlbumDetailView(album: album).environmentObject(playlistViewModel)) {
                                        VStack {
                                            AsyncImage(url: album.imageURL) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(8)
                                            
                                            Text(album.name)
                                                .font(.headline)
                                                .lineLimit(1)
                                                .foregroundColor(.primary)
                                        }
                                        .padding()
                                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    // トラック表示（リスト）
                    List {
                        ForEach(viewModel.searchResults) { item in
                            if case .track(let track) = item {
                                let trackItem = PlaylistTrackItem(added_at: "", track: track)
                                
                                                        Button(action: {
                                
                                                            if viewModel.isEditing {
                                
                                                                viewModel.toggleSelection(for: track.id)
                                
                                                            } else {
                                
                                                                #if DEBUG
                                
                                                                print("Playing track: \(track.name)")
                                
                                                                #endif
                                
                                                            }
                                
                                                        }) {
                                
                                
                                    TrackRowView(
                                        item: trackItem,
                                        isEditing: viewModel.isEditing,
                                        isSelected: viewModel.selectedTrackIDs.contains(track.id)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                .listRowSeparator(.visible)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showAddToPlaylistDialog) {
            // トラック一覧のみを抽出して渡す
            let tracks = viewModel.searchResults.compactMap { item -> Track? in
                if case .track(let t) = item { return t }
                return nil
            }
            
            AddToPlaylistSheet(
                isPresented: $showAddToPlaylistDialog,
                selectedTrackIDs: viewModel.selectedTrackIDs,
                tracks: tracks,
                playlistViewModel: playlistViewModel
            )
        }
    }
}

// プレイリスト追加ダイアログ
struct AddToPlaylistSheet: View {
    @Binding var isPresented: Bool
    let selectedTrackIDs: Set<String>
    let tracks: [Track]
    @ObservedObject var playlistViewModel: PlaylistViewModel
    var excludedPlaylistID: String? = nil // 自分自身を除外するためのID
    
    @State private var selectedPlaylistID: String = ""
    @State private var newPlaylistName: String = ""
    @State private var isCreatingNew = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add to Playlist")
                .font(.headline)
            
            Picker("", selection: $isCreatingNew) {
                Text("Existing Playlist").tag(false)
                Text("New Playlist").tag(true)
            }
            .pickerStyle(.segmented)
            
            if isCreatingNew {
                TextField("Playlist Name", text: $newPlaylistName)
                    .textFieldStyle(.roundedBorder)
            } else {
                Picker("Select Playlist", selection: $selectedPlaylistID) {
                    Text("Select a playlist").tag("")
                    ForEach(playlistViewModel.playlists) { playlist in
                        // 自分自身は除外
                        if playlist.id != excludedPlaylistID {
                            Text(playlist.name).tag(playlist.id)
                        }
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Add") {
                    addTracks()
                }
                .disabled(isCreatingNew ? newPlaylistName.isEmpty : selectedPlaylistID.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private func addTracks() {
        // 対象のURIリストを作成
        let uris = tracks
            .filter { selectedTrackIDs.contains($0.id) }
            .map { $0.uri }
        
        guard !uris.isEmpty else { return }
        
        if isCreatingNew {
            // 新規作成して追加
            guard !newPlaylistName.isEmpty else { return }
            playlistViewModel.createPlaylistAndAddTracks(name: newPlaylistName, trackURIs: uris)
        } else {
            // 既存に追加
            guard !selectedPlaylistID.isEmpty else { return }
            playlistViewModel.addTracksToPlaylist(playlistID: selectedPlaylistID, trackURIs: uris)
        }
        isPresented = false
    }
}
