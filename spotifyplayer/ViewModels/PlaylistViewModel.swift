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
                    #if DEBUG
                    print("Error fetching playlists: \(error)")
                    #endif
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
                    #if DEBUG
                    print("Error fetching tracks: \(error)")
                    #endif
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
        
        #if DEBUG
        print("Reorder in \(playlist.name): src=\(sourceIndex), dest=\(destination)")
        #endif
        
        SpotifyAPIService.shared.reorderPlaylistTracks(accessToken: token, playlistID: playlist.id, rangeStart: sourceIndex, insertBefore: apiInsertBefore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("Error reordering tracks: \(error)")
                    #endif
                }
            }, receiveValue: { _ in
                #if DEBUG
                print("Successfully reordered track via API")
                #endif
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
    
    // 全選択
    func selectAllTracks() {
        let allIDs = tracks.map { $0.id }
        selectedTrackIDs = Set(allIDs)
    }
    
    // 選択解除
    func clearSelection() {
        selectedTrackIDs.removeAll()
    }
    
    // 削除機能実装
    func deleteSelectedTracks(in playlist: Playlist) {
        guard let token = authService.accessToken else {
            #if DEBUG
            print("Delete failed: No token")
            #endif
            return
        }
        
        #if DEBUG
        print("Attempting to delete from playlist: \(playlist.name). Selected IDs: \(selectedTrackIDs)")
        #endif
        
        isLoading = true
        
        // IDからURIへのマッピング（削除APIはURIが必要）
        // tracks配列から、selectedTrackIDsに含まれる楽曲のURIを探す
        let tracksToDelete = tracks.filter { selectedTrackIDs.contains($0.id) }
        let urisToDelete = tracksToDelete.map { $0.track.uri }
        
        #if DEBUG
        print("Found \(tracksToDelete.count) tracks to delete. URIs: \(urisToDelete)")
        #endif
        
        guard !urisToDelete.isEmpty else {
            #if DEBUG
            print("Delete failed: No matching tracks found for selected IDs.")
            #endif
            isLoading = false
            return
        }
        
        #if DEBUG
        print("Sending delete request to API...")
        #endif
        
        SpotifyAPIService.shared.removeTracksFromPlaylist(accessToken: token, playlistID: playlist.id, trackURIs: urisToDelete)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    #if DEBUG
                    print("API Error during delete: \(error)")
                    #endif
                }
            }, receiveValue: { [weak self] _ in
                #if DEBUG
                print("Successfully deleted tracks")
                #endif
                // ローカル配列からも削除してUI反映
                self?.tracks.removeAll { self?.selectedTrackIDs.contains($0.id) ?? false }
                self?.selectedTrackIDs.removeAll()
                self?.isEditing = false // 編集モード終了
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Add Tracks to Playlist
    
    /// 既存のプレイリストに楽曲を追加する
    func addTracksToPlaylist(playlistID: String, trackURIs: [String]) {
        guard let token = authService.accessToken else { return }
        
        isLoading = true
        
        SpotifyAPIService.shared.addTracksToPlaylist(accessToken: token, playlistID: playlistID, trackURIs: trackURIs)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to add tracks: \(error.localizedDescription)"
                    #if DEBUG
                    print("Error adding tracks: \(error)")
                    #endif
                }
            }, receiveValue: { [weak self] _ in
                #if DEBUG
                print("Successfully added tracks to playlist \(playlistID)")
                #endif
                // 追加先が現在選択中のプレイリストなら再読み込み
                if self?.selectedPlaylist?.id == playlistID {
                    if let playlist = self?.selectedPlaylist {
                        self?.fetchTracks(for: playlist)
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    /// 新規プレイリストを作成して楽曲を追加する
    func createPlaylistAndAddTracks(name: String, trackURIs: [String]) {
        guard let token = authService.accessToken else { return }
        
        isLoading = true
        
        // 1. ユーザーID取得 -> 2. 作成 -> 3. 追加
        SpotifyAPIService.shared.getCurrentUser(accessToken: token)
            .flatMap { user -> AnyPublisher<Playlist, Error> in
                return SpotifyAPIService.shared.createPlaylist(accessToken: token, userID: user.id, name: name)
            }
            .flatMap { playlist -> AnyPublisher<Void, Error> in
                // 作成成功したらローカルのプレイリスト一覧に追加（API完了待たずに）
                DispatchQueue.main.async {
                    self.playlists.insert(playlist, at: 0)
                }
                return SpotifyAPIService.shared.addTracksToPlaylist(accessToken: token, playlistID: playlist.id, trackURIs: trackURIs)
            }
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to create playlist: \(error.localizedDescription)"
                    #if DEBUG
                    print("Error creating playlist: \(error)")
                    #endif
                }
            }, receiveValue: {
                #if DEBUG
                print("Successfully created playlist and added tracks")
                #endif
            })
            .store(in: &cancellables)
    }
}

