// rule.mdを読むこと
import Foundation
import Combine

class PlayerViewModel: ObservableObject {
    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var progressMs: Int = 0
    @Published var durationMs: Int = 1
    @Published var availableDevices: [Device] = []
    @Published var activeDevice: Device?
    @Published var isShuffle = false
    @Published var repeatState = "off"
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = SpotifyAuthService.shared
    private var timer: AnyCancellable?
    
    init() {
        // 定期的に状態を更新 (ポーリング)
        startPolling()
    }
    
    func startPolling() {
        timer = Timer.publish(every: 3.0, on: .main, in: .common) // 3秒ごとに更新
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshState()
            }
    }
    
    func refreshState() {
        guard let token = authService.accessToken else { return }
        
        // 再生状態の取得
        SpotifyAPIService.shared.getPlaybackState(accessToken: token)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] state in
                guard let self = self else { return }
                guard let state = state else {
                    // 再生されていない場合
                    self.isPlaying = false
                    return
                }
                
                self.currentTrack = state.item
                self.isPlaying = state.is_playing
                self.progressMs = state.progress_ms ?? 0
                self.durationMs = state.item?.duration_ms ?? 1
                self.activeDevice = state.device
                self.isShuffle = state.shuffle_state
                self.repeatState = state.repeat_state
            })
            .store(in: &cancellables)
        
        // デバイス一覧の取得
        SpotifyAPIService.shared.getAvailableDevices(accessToken: token)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] devices in
                self?.availableDevices = devices
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func togglePlayPause() {
        guard let token = authService.accessToken else { return }
        if isPlaying {
            SpotifyAPIService.shared.pause(accessToken: token).sink(receiveCompletion: {_ in}, receiveValue: {}).store(in: &cancellables)
            isPlaying = false // 即時反映
        } else {
            SpotifyAPIService.shared.play(accessToken: token).sink(receiveCompletion: {_ in}, receiveValue: {}).store(in: &cancellables)
            isPlaying = true // 即時反映
        }
        // 少し遅れて状態を再取得
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refreshState() }
    }
    
    func nextTrack() {
        guard let token = authService.accessToken else { return }
        SpotifyAPIService.shared.next(accessToken: token).sink(receiveCompletion: {_ in}, receiveValue: {}).store(in: &cancellables)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refreshState() }
    }
    
    func previousTrack() {
        guard let token = authService.accessToken else { return }
        SpotifyAPIService.shared.previous(accessToken: token).sink(receiveCompletion: {_ in}, receiveValue: {}).store(in: &cancellables)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refreshState() }
    }
    
    func playTrack(_ uri: String, contextURI: String? = nil) {
        guard let token = authService.accessToken else { return }
        // プレイリストコンテキストがある場合は、その中での再生を指定
        SpotifyAPIService.shared.play(accessToken: token, contextURI: contextURI, offsetURI: uri)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Play error: \(error)") // ログ整理時はDEBUG化推奨
                }
            }, receiveValue: { [weak self] in
                self?.isPlaying = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self?.refreshState() }
            })
            .store(in: &cancellables)
    }
    
    func toggleShuffle() {
        guard let token = authService.accessToken else { return }
        let newState = !isShuffle
        SpotifyAPIService.shared.setShuffle(accessToken: token, state: newState)
            .sink(receiveCompletion: {_ in}, receiveValue: {}).store(in: &cancellables)
        isShuffle = newState
    }
    
    func toggleRepeat() {
        guard let token = authService.accessToken else { return }
        // off -> context -> track -> off
        let newState: String
        switch repeatState {
        case "off": newState = "context"
        case "context": newState = "track"
        default: newState = "off"
        }
        SpotifyAPIService.shared.setRepeat(accessToken: token, state: newState)
            .sink(receiveCompletion: {_ in}, receiveValue: {}).store(in: &cancellables)
        repeatState = newState
    }
    
    // デバイス選択
    func transferPlayback(to deviceID: String) {
        // Transfer APIの実装はまだだが、playコマンドでdevice_id指定することで切り替え可能
        guard let token = authService.accessToken else { return }
        SpotifyAPIService.shared.play(accessToken: token, deviceID: deviceID)
            .sink(receiveCompletion: {_ in}, receiveValue: {}).store(in: &cancellables)
    }
}
