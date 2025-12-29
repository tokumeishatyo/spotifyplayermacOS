// rule.mdを読むこと
import SwiftUI

struct PlayerBarView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // 左側: 曲情報
                HStack(spacing: 12) {
                    if let track = viewModel.currentTrack {
                        AsyncImage(url: track.album?.imageURL) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(4)
                        
                        VStack(alignment: .leading) {
                            Text(track.name)
                                .font(.headline)
                                .lineLimit(1)
                            Text(track.artistNames)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Color.clear.frame(width: 50, height: 50)
                        Text("Not Playing")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 250, alignment: .leading)
                
                Spacer()
                
                // 中央: コントロール
                VStack(spacing: 4) {
                    HStack(spacing: 20) {
                        Button(action: { viewModel.toggleShuffle() }) {
                            Image(systemName: "shuffle")
                                .foregroundColor(viewModel.isShuffle ? .green : .primary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { viewModel.previousTrack() }) {
                            Image(systemName: "backward.fill")
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { viewModel.togglePlayPause() }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { viewModel.nextTrack() }) {
                            Image(systemName: "forward.fill")
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { viewModel.toggleRepeat() }) {
                            Image(systemName: viewModel.repeatState == "off" ? "repeat" : (viewModel.repeatState == "track" ? "repeat.1" : "repeat"))
                                .foregroundColor(viewModel.repeatState != "off" ? .green : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // プログレスバー (表示のみ)
                    ProgressView(value: Double(viewModel.progressMs), total: Double(viewModel.durationMs))
                        .frame(width: 300)
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                }
                
                Spacer()
                
                // 右側: デバイス選択
                HStack {
                    // ミニプレイヤーボタン
                    Button(action: {
                        // 先に自分（メイン）のウィンドウ参照を取得しておく
                        // (SwiftUIのViewからは直接NSWindow取れないため、NSAppから探す)
                        // keyWindowは自分のはずだが、タイミングによるので、
                        // 「ミニプレイヤー」というタイトルでないウィンドウを閉じる方針にする。
                        
                        let mainWindows = NSApplication.shared.windows.filter { $0.title != "Mini Player" }
                        
                        openWindow(id: "mini-player")
                        
                        // 少し遅延させてメインを閉じる（アニメーション競合回避）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            mainWindows.forEach { $0.close() }
                        }
                    }) {
                        Image(systemName: "rectangle.compress.vertical")
                            .help("Mini Player")
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    
                    Image(systemName: "hifispeaker")
                    
                    if viewModel.availableDevices.isEmpty {
                        Text("No Devices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Menu {
                            ForEach(viewModel.availableDevices) { device in
                                Button(action: {
                                    viewModel.transferPlayback(to: device.id ?? "")
                                }) {
                                    if device.is_active {
                                        Label(device.name, systemImage: "checkmark")
                                    } else {
                                        Text(device.name)
                                    }
                                }
                            }
                        } label: {
                            Text(viewModel.activeDevice?.name ?? "Select Device")
                                .font(.caption)
                                .frame(width: 100)
                                .lineLimit(1)
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                .frame(width: 200, alignment: .trailing)
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}
