// rule.mdを読むこと
import Foundation

struct Playlist: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let tracks: [Track] // 将来的に使用
}

// UI構築用ダミー
struct Track: Identifiable, Hashable {
    let id: String
    let name: String
    let artist: String
}
