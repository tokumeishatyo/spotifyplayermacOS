// rule.mdを読むこと
import SwiftUI
import UniformTypeIdentifiers

struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var viewModel: PlaylistViewModel
    @State private var showDeleteConfirmation = false
    @State private var showAddToPlaylistDialog = false
    @State private var draggingItem: PlaylistTrackItem? // ドラッグ中のアイテム
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー部分
            HStack(alignment: .top, spacing: 16) {
                // プレイリスト画像
                AsyncImage(url: playlist.imageURL) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 120, height: 120)
                .cornerRadius(8)
                .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("PLAYLIST")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text(playlist.name)
                        .font(.system(size: 40, weight: .bold))
                    
                    if let description = playlist.description, !description.isEmpty, description != "null" {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // 楽曲数表示
                    Text("\(viewModel.tracks.count) songs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    
                    HStack {
                        // 編集ボタン
                        Button(action: {
                            withAnimation {
                                viewModel.isEditing.toggle()
                            }
                        }) {
                            Text(viewModel.isEditing ? "完了" : "編集")
                                .frame(width: 80)
                        }
                        .buttonStyle(.bordered)
                        
                        if viewModel.isEditing {
                            // 全選択ボタン
                            Button(action: {
                                viewModel.selectAllTracks()
                            }) {
                                Image(systemName: "checklist.checked")
                                    .help("Select All")
                            }
                            
                            // 選択解除ボタン
                            Button(action: {
                                viewModel.clearSelection()
                            }) {
                                Image(systemName: "xmark.circle")
                                    .help("Clear Selection")
                            }
                            .disabled(viewModel.selectedTrackIDs.isEmpty)
                        }
                        
                        // プレイリストに追加ボタン（編集モードかつ選択時）
                        Button(action: {
                            showAddToPlaylistDialog = true
                        }) {
                            Label("追加", systemImage: "plus.circle")
                        }
                        .disabled(!viewModel.isEditing || viewModel.selectedTrackIDs.isEmpty)
                        
                        // 削除ボタン（編集モードかつ選択がある場合のみ活性化）
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("削除", systemImage: "trash")
                        }
                        .disabled(!viewModel.isEditing || viewModel.selectedTrackIDs.isEmpty)
                        .tint(.red)
                    }
                    .padding(.top, 8)
                }
                Spacer()
            }
            .padding(24)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5)) // ヘッダー背景
            
            Divider()
            
            // 楽曲リスト部分
            if viewModel.isLoading && viewModel.tracks.isEmpty {
                Spacer()
                ProgressView("Loading tracks...")
                Spacer()
            } else if viewModel.tracks.isEmpty {
                Spacer()
                Text("No tracks found in this playlist.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, item in
                        Button(action: {
                            if viewModel.isEditing {
                                viewModel.toggleSelection(for: item.id)
                            } else {
                                #if DEBUG
                                print("Playing track: \(item.track.name)")
                                #endif
                                // TODO: 再生処理
                            }
                        }) {
                            TrackRowView(
                                item: item,
                                isEditing: viewModel.isEditing,
                                isSelected: viewModel.selectedTrackIDs.contains(item.id)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.visible)
                        // ドラッグ＆ドロップ実装
                        .onDrag {
                            self.draggingItem = item
                            return NSItemProvider(object: item.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: DropViewDelegate(
                            item: item,
                            viewModel: viewModel,
                            currentPlaylist: playlist,
                            draggingItem: $draggingItem
                        ))
                    }
                }
                .listStyle(.plain)
            }
        }
        .confirmationDialog("選択した曲を削除しますか？", isPresented: $showDeleteConfirmation) {
            Button("削除", role: .destructive) {
                viewModel.deleteSelectedTracks(in: playlist)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。プレイリストから\(viewModel.selectedTrackIDs.count)曲が削除されます。")
        }
        .sheet(isPresented: $showAddToPlaylistDialog) {
            // 選択されたTrackのみを抽出
            let selectedTracks = viewModel.tracks
                .filter { viewModel.selectedTrackIDs.contains($0.id) }
                .map { $0.track }
            
            AddToPlaylistSheet(
                isPresented: $showAddToPlaylistDialog,
                selectedTrackIDs: viewModel.selectedTrackIDs,
                tracks: selectedTracks,
                playlistViewModel: viewModel,
                excludedPlaylistID: playlist.id // 自分自身を除外
            )
        }
        .onAppear {
            // 画面表示時に楽曲を読み込む
}
        .onChange(of: playlist) { oldPlaylist, newPlaylist in
            viewModel.fetchTracks(for: newPlaylist)
        }
    }
}

// ドロップ処理を管理するDelegate
struct DropViewDelegate: DropDelegate {
    let item: PlaylistTrackItem
    let viewModel: PlaylistViewModel
    let currentPlaylist: Playlist
    @Binding var draggingItem: PlaylistTrackItem?
    
    func dropEntered(info: DropInfo) {
        // 必要ならここで並べ替えのプレビュー処理を行う
        // 今回は単純化のため省略
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggingItem = draggingItem,
              let fromIndex = viewModel.tracks.firstIndex(where: { $0.id == draggingItem.id }),
              let toIndex = viewModel.tracks.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        
        if fromIndex != toIndex {
            // 移動処理を実行
            withAnimation {
                let fromOffsets = IndexSet(integer: fromIndex)
                // toIndexが後ろの場合は+1するなどの調整が必要な場合があるが、
                // moveTracksの実装に合わせて調整。
                // ListのonMoveと違い、ここは単純なインデックス指定になる。
                
                let destination = (toIndex > fromIndex) ? toIndex + 1 : toIndex
                viewModel.moveTracks(from: fromOffsets, to: destination, in: currentPlaylist)
            }
        }
        
        self.draggingItem = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct TrackRowView: View {
    let item: PlaylistTrackItem
    let isEditing: Bool
    let isSelected: Bool
    var fallbackImageURL: URL? = nil // 追加: アルバム詳細などで画像がない場合の予備
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                // 選択チェックボックス
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title3)
                    .frame(width: 24)
                
                // ドラッグハンドル
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .frame(width: 24)
            }
            
            AsyncImage(url: item.track.album?.imageURL ?? fallbackImageURL) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 40, height: 40)
            .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.track.name)
                    .font(.body)
                    .foregroundColor(isSelected && isEditing ? .green : .primary)
                    .lineLimit(1)
                
                Text(item.track.artistNames)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(item.track.album?.name ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 150, alignment: .leading)
            
            Text(item.track.durationFormatted)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .frame(height: 56)
    }
}
