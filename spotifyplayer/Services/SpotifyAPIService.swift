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
    
    // MARK: - Search & Recommendations
    
    /// 検索を実行する（結果全体を返す）
    /// - Parameters:
    ///   - query: 検索キーワード
    ///   - type: 検索タイプ（"track", "artist", "album" など）
    ///   - limit: 取得件数
    func search(accessToken: String, query: String, type: String, limit: Int) -> AnyPublisher<SearchResponse, Error> {
        // クエリのエンコード
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&type=\(type)&limit=\(limit)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// アルバム内の楽曲一覧を取得する
    func fetchAlbumTracks(accessToken: String, albumID: String) -> AnyPublisher<[Track], Error> {
        guard let url = URL(string: "\(baseURL)/albums/\(albumID)/tracks?limit=50") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TrackSearchResult.self, decoder: JSONDecoder()) // Album tracks response structure mimics search result tracks
            .map(\.items)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// おすすめ（気分検索）を取得する
    /// - Parameters:
    ///   - seedGenres: シードとなるジャンル（カンマ区切り）
    ///   - targetAttributes: ターゲット属性（valence, energyなど）
    ///   - limit: 取得件数
    func getRecommendations(accessToken: String, seedGenres: String, targetAttributes: [String: Double], limit: Int) -> AnyPublisher<[Track], Error> {
        var components = URLComponents(string: "\(baseURL)/recommendations")!
        var queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "seed_genres", value: seedGenres)
        ]
        
        // ターゲット属性（target_valence=0.8 など）を追加
        for (key, value) in targetAttributes {
            queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: RecommendationsResponse.self, decoder: JSONDecoder())
            .map(\.tracks)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Playlist Creation & Adding Tracks
    
    /// 現在のユーザー情報を取得する
    func getCurrentUser(accessToken: String) -> AnyPublisher<User, Error> {
        guard let url = URL(string: "\(baseURL)/me") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// 新規プレイリストを作成する
    /// - Returns: 作成されたプレイリスト
    func createPlaylist(accessToken: String, userID: String, name: String) -> AnyPublisher<Playlist, Error> {
        guard let url = URL(string: "\(baseURL)/users/\(userID)/playlists") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "description": "Created with Spotify Player App",
            "public": false // デフォルトはPrivate
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Playlist.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// プレイリストに楽曲を追加する
    func addTracksToPlaylist(accessToken: String, playlistID: String, trackURIs: [String]) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "uris": trackURIs
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
                    // エラーハンドリング
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
