// rule.mdを読むこと
import Foundation
import Combine

class SpotifyAPIService {
    static let shared = SpotifyAPIService()
    
    private let baseURL = "https://api.spotify.com/v1"
    
    /// ユーザーのプレイリスト一覧を取得する
    /// - Parameter accessToken: 有効なアクセストークン
    /// - Returns: プレイリストの配列をPublisherで返す
    func fetchPlaylists(accessToken: String) -> AnyPublisher<[Playlist], Error> {
        guard let url = URL(string: "\(baseURL)/me/playlists?limit=50") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: PagedPlaylistsResponse.self, decoder: JSONDecoder())
            .map(\.items)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
