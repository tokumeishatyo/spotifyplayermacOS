// rule.mdを読むこと
import Foundation
import Combine
import SwiftUI

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var selectedPlaylist: Playlist? {
        didSet {
            // プレイリストが変更されたら編集モード等をリセット
            // fetchTracksはViewのonAppearで呼ぶように変更
            isEditing = false
            selectedTrackIDs = []
            tracks = [] 
        }
    }
    @Published var tracks: [PlaylistTrackItem] = []
    
    // 編集モード関連
    @Published var isEditing = false
    @Published var selectedTrackIDs: Set<String> = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = SpotifyAuthService.shared
    
    init() {
        // アクセストークンが取得されたら自動的にプレイリストを読み込む
        authService.$accessToken
            .compactMap { $0 }
            .sink { [weak self] token in
                self?.fetchPlaylists(token: token)
            }
            .store(in: &cancellables)
    }
    
    func fetchPlaylists(token: String) {
        isLoading = true
        errorMessage = nil
        
        SpotifyAPIService.shared.fetchPlaylists(accessToken: token)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("Error fetching playlists: \(error)")
                }
            }, receiveValue: { [weak self] playlists in
                self?.playlists = playlists
            })
            .store(in: &cancellables)
    }
    
    func fetchTracks(for playlist: Playlist) {
        guard let token = authService.accessToken else { return }
        
        isLoading = true
        errorMessage = nil
        tracks = [] // リセット
        
        fetchTracksRecursive(token: token, playlistID: playlist.id, offset: 0)
    }
    
    private func fetchTracksRecursive(token: String, playlistID: String, offset: Int) {
        SpotifyAPIService.shared.fetchPlaylistTracks(accessToken: token, playlistID: playlistID, offset: offset)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    print("Error fetching tracks: \(error)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // 取得した楽曲を追加（空IDなどを除外）
                let validItems = response.items.filter { !$0.track.id.isEmpty }
                self.tracks.append(contentsOf: validItems)
                
                // 次のページがある場合は再帰的に取得
                if response.next != nil {
                    self.fetchTracksRecursive(token: token, playlistID: playlistID, offset: offset + response.limit)
                } else {
                    self.isLoading = false
                }
            })
            .store(in: &cancellables)
    }
    
    // UI上の並べ替え（onMove用）
    func moveTracks(from source: IndexSet, to destination: Int, in playlist: Playlist) {
        guard let token = authService.accessToken else { return }
        
        // 移動元のインデックス（単一選択を想定）
        guard let sourceIndex = source.first else { return }
        
        // 1. UI上で反映
        tracks.move(fromOffsets: source, toOffset: destination)
        
        // 2. API用のインデックス補正
        let apiInsertBefore = destination
        
        print("Reorder in \(playlist.name): src=\(sourceIndex), dest=\(destination)")
        
        SpotifyAPIService.shared.reorderPlaylistTracks(accessToken: token, playlistID: playlist.id, rangeStart: sourceIndex, insertBefore: apiInsertBefore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error reordering tracks: \(error)")
                }
            }, receiveValue: { _ in
                print("Successfully reordered track via API")
            })
            .store(in: &cancellables)
    }
    
    // 編集操作：チェックボックスの切り替え
    func toggleSelection(for trackID: String) {
        if selectedTrackIDs.contains(trackID) {
            selectedTrackIDs.remove(trackID)
        } else {
            selectedTrackIDs.insert(trackID)
        }
    }
    
    // 削除機能実装
    func deleteSelectedTracks(in playlist: Playlist) {
        guard let token = authService.accessToken else {
            print("Delete failed: No token")
            return
        }
        
        print("Attempting to delete from playlist: \(playlist.name). Selected IDs: \(selectedTrackIDs)")
        
        isLoading = true
        
        // IDからURIへのマッピング（削除APIはURIが必要）
        // tracks配列から、selectedTrackIDsに含まれる楽曲のURIを探す
        let tracksToDelete = tracks.filter { selectedTrackIDs.contains($0.id) }
        let urisToDelete = tracksToDelete.map { $0.track.uri }
        
        print("Found \(tracksToDelete.count) tracks to delete. URIs: \(urisToDelete)")
        
        guard !urisToDelete.isEmpty else {
            print("Delete failed: No matching tracks found for selected IDs.")
            isLoading = false
            return
        }
        
        print("Sending delete request to API...")
        
        SpotifyAPIService.shared.removeTracksFromPlaylist(accessToken: token, playlistID: playlist.id, trackURIs: urisToDelete)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    print("API Error during delete: \(error)")
                }
            }, receiveValue: { [weak self] _ in
                print("Successfully deleted tracks")
                // ローカル配列からも削除してUI反映
                self?.tracks.removeAll { self?.selectedTrackIDs.contains($0.id) ?? false }
                self?.selectedTrackIDs.removeAll()
                self?.isEditing = false // 編集モード終了
            })
            .store(in: &cancellables)
    }
}

