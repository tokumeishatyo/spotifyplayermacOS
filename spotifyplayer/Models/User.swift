// rule.mdを読むこと
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let display_name: String?
    let email: String?
    let images: [SpotifyImage]?
}
