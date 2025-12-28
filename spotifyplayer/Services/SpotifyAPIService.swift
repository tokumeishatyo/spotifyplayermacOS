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
    
    /// プレイリスト内の楽曲一覧を取得する
    /// - Parameters:
    ///   - accessToken: 有効なアクセストークン
    ///   - playlistID: 対象のプレイリストID
    ///   - offset: 取得開始位置（ページネーション用）
    /// - Returns: 楽曲アイテム（PlaylistTrackItem）の配列
    func fetchPlaylistTracks(accessToken: String, playlistID: String, offset: Int = 0) -> AnyPublisher<PlaylistTrackResponse, Error> {
        guard let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks?limit=50&offset=\(offset)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: PlaylistTrackResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// プレイリストから指定した楽曲を一括削除する
    func removeTracksFromPlaylist(accessToken: String, playlistID: String, trackURIs: [String]) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 削除リクエストボディの作成
        let tracksBody = trackURIs.map { ["uri": $0] }
        let body = ["tracks": tracksBody]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if !(200..<300 ~= httpResponse.statusCode) {
                    if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorJSON["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw NSError(domain: "SpotifyAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                    }
                    throw URLError(.init(rawValue: httpResponse.statusCode))
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// プレイリスト内の楽曲順序を変更する
    /// - Parameters:
    ///   - rangeStart: 移動する楽曲の現在のインデックス（0始まり）
    ///   - insertBefore: 移動先のインデックス
    func reorderPlaylistTracks(accessToken: String, playlistID: String, rangeStart: Int, insertBefore: Int) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "range_start": rangeStart,
            "insert_before": insertBefore,
            "range_length": 1
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if !(200..<300 ~= httpResponse.statusCode) {
                    if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorJSON["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw NSError(domain: "SpotifyAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                    }
                    throw URLError(.init(rawValue: httpResponse.statusCode))
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
