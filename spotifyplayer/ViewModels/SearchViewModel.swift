// rule.mdを読むこと
import Foundation
import Combine

enum SearchCategory: String, CaseIterable, Identifiable {
    case track = "Track"
    case artist = "Artist"
    case album = "Album"
    
    var id: String { self.rawValue }
}

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: SearchCategory = .track
    @Published var searchLimit = 20
    
    @Published var searchResults: [SearchResultItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 編集モード（検索結果からの選択用）
    @Published var isEditing = false
    @Published var selectedTrackIDs: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = SpotifyAuthService.shared
    
    // 検索実行
    func performSearch() {
        guard let token = authService.accessToken else { return }
        
        // クリア処理（再検索時）
        searchResults = []
        isEditing = false
        selectedTrackIDs = []
        
        isLoading = true
        errorMessage = nil
        
        // 通常検索
        let query = searchText
        if query.isEmpty {
            isLoading = false
            return
        }
        
        var type = "track"
        if selectedCategory == .artist {
            // Artistの場合も一旦track検索にするか、あるいはArtist検索にするか。
            // 今回の要件（アルバムはアルバムとして表示）に合わせ、Albumは"album"で検索する。
            // Artistは要件が曖昧だが、一旦Track検索（artist:Query）のままとする。
            type = "track"
        } else if selectedCategory == .album {
            type = "album"
        }
        
        // Artist指定の場合のクエリ調整
        let finalQuery = (selectedCategory == .artist) ? "artist:\(searchText)" : searchText
        
        #if DEBUG
        print("Searching: \(finalQuery), Type: \(type)")
        #endif
        
        SpotifyAPIService.shared.search(
            accessToken: token,
            query: finalQuery,
            type: type,
            limit: searchLimit
        )
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.errorMessage = error.localizedDescription
                #if DEBUG
                print("Search Error: \(error)")
                #endif
            }
        }, receiveValue: { [weak self] response in
            guard let self = self else { return }
            
            if self.selectedCategory == .album {
                // アルバム結果をラップ
                let albums = response.albums?.items ?? []
                self.searchResults = albums.map { .album($0) }
                #if DEBUG
                print("Search found \(albums.count) albums")
                #endif
            } else {
                // トラック結果をラップ
                let tracks = response.tracks?.items ?? []
                self.searchResults = tracks.map { .track($0) }
                #if DEBUG
                print("Search found \(tracks.count) tracks")
                #endif
            }
        })
        .store(in: &cancellables)
    }
    
    // クリア機能
    func clearAll() {
        searchText = ""
        searchResults = []
        isEditing = false
        selectedTrackIDs = []
        errorMessage = nil
    }
    
    // 選択トグル
    func toggleSelection(for trackID: String) {
        if selectedTrackIDs.contains(trackID) {
            selectedTrackIDs.remove(trackID)
        } else {
            selectedTrackIDs.insert(trackID)
        }
    }
    
    // プレイリストに追加（後ほど実装）
    func addSelectedTracksToPlaylist(playlistID: String) {
        // TODO
    }
}
