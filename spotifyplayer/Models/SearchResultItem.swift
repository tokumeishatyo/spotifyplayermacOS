// rule.mdを読むこと
import Foundation

enum SearchResultItem: Identifiable {
    case track(Track)
    case album(Album)
    
    var id: String {
        switch self {
        case .track(let t): return t.id
        case .album(let a): return a.id
        }
    }
}
