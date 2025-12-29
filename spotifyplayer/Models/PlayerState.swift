// rule.mdを読むこと
import Foundation

struct Device: Codable, Identifiable, Hashable {
    let id: String?
    let is_active: Bool
    let is_private_session: Bool
    let is_restricted: Bool
    let name: String
    let type: String
    let volume_percent: Int?
}

struct DeviceResponse: Codable {
    let devices: [Device]
}

struct PlaybackState: Codable {
    let device: Device?
    let repeat_state: String // off, track, context
    let shuffle_state: Bool
    let is_playing: Bool
    let item: Track?
    let progress_ms: Int?
}

// 再生APIのリクエストボディ用
struct PlayRequest: Codable {
    let context_uri: String?
    let uris: [String]?
    let offset: PlayOffset?
    let position_ms: Int?
}

struct PlayOffset: Codable {
    let position: Int?
    let uri: String?
}
