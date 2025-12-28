// rule.mdを読むこと
import Foundation
import Combine

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var selectedPlaylist: Playlist?
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
                // 最初のプレイリストを選択状態にするなどの処理はここ
            })
            .store(in: &cancellables)
    }
}
