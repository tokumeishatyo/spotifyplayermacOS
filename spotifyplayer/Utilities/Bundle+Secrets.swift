// rule.mdを読むこと
import Foundation

extension Bundle {
    var spotifyClientID: String {
        guard let value = object(forInfoDictionaryKey: "SpotifyClientID") as? String else {
            fatalError("SpotifyClientID not found in Info.plist. Please check Config.xcconfig and Info.plist settings.")
        }
        return value
    }

    var spotifyRedirectURI: String {
        guard let value = object(forInfoDictionaryKey: "SpotifyRedirectURI") as? String else {
            fatalError("SpotifyRedirectURI not found in Info.plist. Please check Config.xcconfig and Info.plist settings.")
        }
        return value
    }
}
