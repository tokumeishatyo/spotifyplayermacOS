// rule.mdを読むこと
import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismiss) var dismiss // 自分自身を閉じる用
    
    // ウィンドウID
    static let windowID = "mini-player"
    
    var body: some View {
        // コンテンツレイヤー (中央)
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            
            // アートワーク (クリックでメインに戻る)
            if let track = viewModel.currentTrack {
                Button(action: {
                    openWindow(id: "main")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }) {
                    AsyncImage(url: track.album?.imageURL) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 160, height: 160)
                }
                .buttonStyle(.plain)
                .help("Click to return to Main Player")
            }
            
            // 曲情報
            VStack(spacing: 4) {
                Text(viewModel.currentTrack?.name ?? "Not Playing")
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                Text(viewModel.currentTrack?.artistNames ?? "")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .shadow(radius: 2)
            }
            
            // コントロール
            HStack(spacing: 30) {
                Button(action: { viewModel.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                .buttonStyle(.plain)
                
                Button(action: { viewModel.togglePlayPause() }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                .buttonStyle(.plain)
                
                Button(action: { viewModel.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // 背景画像
            if let track = viewModel.currentTrack {
                AsyncImage(url: track.album?.imageURL) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.black
                }
                .overlay(.ultraThinMaterial)
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .frame(minWidth: 280, minHeight: 400)
    }
}
