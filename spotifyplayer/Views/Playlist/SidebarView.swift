// rule.mdを読むこと
import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: PlaylistViewModel
    @Binding var selectedPlaylist: Playlist?
    
    var body: some View {
        List(selection: $selectedPlaylist) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                Section(header: Text("Library")) {
                    ForEach(viewModel.playlists) { playlist in
                        NavigationLink(value: playlist) {
                            HStack(spacing: 12) {
                                AsyncImage(url: playlist.imageURL) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(4)
                                
                                Text(playlist.name)
                                    .font(.body)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 250) // サイドバーの幅を少し広めに設定
    }
}
