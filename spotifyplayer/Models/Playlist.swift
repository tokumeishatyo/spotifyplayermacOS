// rule.mdを読むこと
import Foundation

struct Playlist: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String?
    let images: [SpotifyImage]?
    let uri: String
    let tracks: TracksInfo?
    
    // UI用のヘルパー
    var imageURL: URL? {
        guard let urlString = images?.first?.url else { return nil }
        return URL(string: urlString)
    }
}

struct SpotifyImage: Codable, Hashable {
    let url: String
    let height: Int?
    let width: Int?
}

struct TracksInfo: Codable, Hashable {
    let href: String
    let total: Int
}

// APIレスポンス全体
struct PagedPlaylistsResponse: Codable {
    let href: String
    let items: [Playlist]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}
