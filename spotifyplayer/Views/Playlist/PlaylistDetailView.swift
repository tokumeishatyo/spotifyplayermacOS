// rule.mdを読むこと
import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    
    var body: some View {
        VStack {
            Text(playlist.name)
                .font(.largeTitle)
                .padding()
            
            if let description = playlist.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // TODO: ここに楽曲リストが入る
            Text("No tracks loaded yet.")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .padding()
    }
}
