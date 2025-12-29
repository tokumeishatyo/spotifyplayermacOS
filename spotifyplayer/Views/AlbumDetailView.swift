// rule.mdを読むこと
import SwiftUI
import Combine

class AlbumDetailViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var isEditing = false
    @Published var selectedTrackIDs: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = SpotifyAuthService.shared
    
    func fetchTracks(albumID: String) {
        guard let token = authService.accessToken else { return }
        
        #if DEBUG
        print("Fetching tracks for album: \(albumID)")
        #endif
        isLoading = true
        
        SpotifyAPIService.shared.fetchAlbumTracks(accessToken: token, albumID: albumID)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("Album detail error: \(error)")
                    #endif
                }
            }, receiveValue: { [weak self] tracks in
                #if DEBUG
                print("Album detail found \(tracks.count) tracks")
                #endif
                self?.tracks = tracks
            })
            .store(in: &cancellables)
    }
    
    func toggleSelection(for trackID: String) {
        if selectedTrackIDs.contains(trackID) {
            selectedTrackIDs.remove(trackID)
        } else {
            selectedTrackIDs.insert(trackID)
        }
    }
    
    func selectAllTracks() {
        let allIDs = tracks.map { $0.id }
        selectedTrackIDs = Set(allIDs)
    }
    
    func clearSelection() {
        selectedTrackIDs.removeAll()
    }
}

struct AlbumDetailView: View {
    let album: Album
    @StateObject private var viewModel = AlbumDetailViewModel()
    @State private var showAddToPlaylistDialog = false
    @EnvironmentObject var playlistViewModel: PlaylistViewModel // MainLayoutViewから共有
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: album.imageURL) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 120, height: 120)
                .cornerRadius(8)
                .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("ALBUM")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text(album.name)
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("\(viewModel.tracks.count) songs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                viewModel.isEditing.toggle()
                            }
                        }) {
                            Text(viewModel.isEditing ? "完了" : "編集")
                                .frame(width: 80)
                        }
                        .buttonStyle(.bordered)
                        
                        if viewModel.isEditing {
                            Button(action: {
                                viewModel.selectAllTracks()
                            }) {
                                Image(systemName: "checklist.checked")
                                    .help("Select All")
                            }
                            
                            Button(action: {
                                viewModel.clearSelection()
                            }) {
                                Image(systemName: "xmark.circle")
                                    .help("Clear Selection")
                            }
                            .disabled(viewModel.selectedTrackIDs.isEmpty)
                        }
                        
                        Button(action: {
                            showAddToPlaylistDialog = true
                        }) {
                            Label("プレイリストに追加", systemImage: "plus.circle")
                        }
                        .disabled(!viewModel.isEditing || viewModel.selectedTrackIDs.isEmpty)
                    }
                    .padding(.top, 8)
                }
                Spacer()
            }
            .padding(24)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // リスト
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.tracks) { track in
                        let item = PlaylistTrackItem(added_at: "", track: track)
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
                                item: item,
                                isEditing: viewModel.isEditing,
                                isSelected: viewModel.selectedTrackIDs.contains(track.id),
                                fallbackImageURL: album.imageURL // 親アルバムの画像を渡す
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.visible)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            viewModel.fetchTracks(albumID: album.id)
        }
        .sheet(isPresented: $showAddToPlaylistDialog) {
            AddToPlaylistSheet(
                isPresented: $showAddToPlaylistDialog,
                selectedTrackIDs: viewModel.selectedTrackIDs,
                tracks: viewModel.tracks,
                playlistViewModel: playlistViewModel
            )
        }
    }
}
