// rule.mdを読むこと
import Foundation

struct SearchResponse: Codable {
    let tracks: TrackSearchResult?
    let artists: ArtistSearchResult?
    let albums: AlbumSearchResult?
}

struct TrackSearchResult: Codable {
    let items: [Track]
}

struct ArtistSearchResult: Codable {
    let items: [Artist]
}

struct AlbumSearchResult: Codable {
    let items: [Album]
}

// Recommendations APIのレスポンス
struct RecommendationsResponse: Codable {
    let tracks: [Track]
}
