// rule.mdを読むこと
import Foundation

struct PlaylistTrackResponse: Codable {
    let href: String
    let items: [PlaylistTrackItem]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

struct PlaylistTrackItem: Codable, Hashable, Identifiable {
    let added_at: String
    let track: Track
    
    // Identifiable準拠のための一意なID
    var id: String { track.id }
}

struct Track: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let artists: [Artist]
    let album: Album
    let duration_ms: Int
    let uri: String
    
    // UI表示用ヘルパー
    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
    
    var durationFormatted: String {
        let seconds = (duration_ms / 1000) % 60
        let minutes = (duration_ms / 1000) / 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Artist: Codable, Hashable {
    let id: String
    let name: String
}

struct Album: Codable, Hashable {
    let id: String
    let name: String
    let images: [SpotifyImage]
    
    var imageURL: URL? {
        guard let urlString = images.first?.url else { return nil }
        return URL(string: urlString)
    }
}
