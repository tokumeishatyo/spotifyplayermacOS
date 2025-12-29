// rule.mdを読むこと
import Foundation
import AuthenticationServices
import Combine

class SpotifyAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = SpotifyAuthService()
    
    @Published var accessToken: String?
    @Published var isAuthorizing = false
    
    private var codeVerifier: String?
    private var cancellables = Set<AnyCancellable>()
    
    private let authEndpoint = "https://accounts.spotify.com/authorize"
    private let tokenEndpoint = "https://accounts.spotify.com/api/token"
    
    override init() {
        super.init()
        // 起動時に自動ログインを試みる
        tryAutoLogin()
    }
    
    private func tryAutoLogin() {
        // Keychainからリフレッシュトークンを取得
        if let refreshToken = KeychainHelper.shared.read(key: "refreshToken") {
            print("Found refresh token, attempting to refresh session...")
            refreshAccessToken(refreshToken: refreshToken)
        }
    }
    
    func authorize() {
        isAuthorizing = true
        
        let verifier = PKCE.generateCodeVerifier()
        self.codeVerifier = verifier
        let challenge = PKCE.generateCodeChallenge(from: verifier)
        
        var components = URLComponents(string: authEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Bundle.main.spotifyClientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Bundle.main.spotifyRedirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: "user-read-private user-read-email playlist-read-private playlist-modify-public playlist-modify-private user-read-playback-state user-modify-playback-state user-read-currently-playing")
        ]
        
        guard let authURL = components.url else { return }
        let callbackScheme = "spotifyplayer"
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.isAuthorizing = false
            }
            
            if let error = error {
                #if DEBUG
                print("Auth error: \(error.localizedDescription)")
                #endif
                return
            }
            
            guard let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                return
            }
            
            self?.exchangeCodeForToken(code: code)
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    private func exchangeCodeForToken(code: String) {
        guard let verifier = codeVerifier else { return }
        
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": Bundle.main.spotifyClientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Bundle.main.spotifyRedirectURI,
            "code_verifier": verifier
        ]
        
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TokenResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Token exchange error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.accessToken = response.access_token
                
                // トークンを保存
                if let refreshToken = response.refresh_token {
                    KeychainHelper.shared.save(refreshToken, key: "refreshToken")
                }
                // アクセストークンも保存しておくとオフライン判定などに使えるが、
                // 基本はリフレッシュトークンがあれば十分。今回は有効期限管理のため簡易的にメモリ保持。
                
                #if DEBUG
                print("Successfully obtained access token!")
                #endif
            })
            .store(in: &cancellables)
    }
    
    // リフレッシュトークンを使ってアクセストークンを更新する
    func refreshAccessToken(refreshToken: String) {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": Bundle.main.spotifyClientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TokenResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Token refresh error: \(error.localizedDescription)")
                    // リフレッシュ失敗時は再ログインが必要なため、Keychainをクリアしてもよい
                    // KeychainHelper.shared.delete(key: "refreshToken")
                }
            }, receiveValue: { [weak self] response in
                self?.accessToken = response.access_token
                
                // 新しいリフレッシュトークンが返ってきた場合は更新
                if let newRefreshToken = response.refresh_token {
                    KeychainHelper.shared.save(newRefreshToken, key: "refreshToken")
                }
                
                #if DEBUG
                print("Successfully refreshed access token!")
                #endif
            })
            .store(in: &cancellables)
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSWindow()
    }
}

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
}
