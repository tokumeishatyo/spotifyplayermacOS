<!-- rule.mdを読むこと -->
# 基本設計書 (Architecture)

## 1. アーキテクチャ概要
本アプリケーションは **MVVM (Model-View-ViewModel)** パターンを採用し、UI（View）とロジック（Model/ViewModel）を明確に分離する。これにより、テスト容易性と保守性を高める。

### 構成要素
- **View (SwiftUI)**: 画面の描画のみを担当。ViewModelの状態（State）を監視し、変更があれば自動的に再描画する。
- **ViewModel (ObservableObject)**: 画面表示に必要な状態（State）を保持し、Viewからのアクションを受け取ってModelを操作する。UIロジックを担当。
- **Model**: アプリケーションのビジネスロジック、データ構造、データアクセス（API通信など）を担当。SwiftUIフレームワークには依存しない。

## 2. モジュール分割・ディレクトリ構成
機能ごとにフォルダを分割し、1ファイルの肥大化を防ぐ。

```
spotifyplayer/
├── App
│   ├── spotifyplayerApp.swift  (エントリーポイント)
│   └── AppState.swift          (グローバルな状態管理)
├── Models
│   ├── Track.swift             (楽曲データモデル)
│   ├── Playlist.swift          (プレイリストデータモデル)
│   └── User.swift              (ユーザー情報モデル)
├── Services
│   ├── SpotifyAuthService.swift(認証処理)
│   ├── SpotifyAPIService.swift (Web API通信)
│   └── PlayerService.swift     (再生制御)
├── ViewModels
│   ├── PlayerViewModel.swift   (再生画面用VM)
│   ├── PlaylistViewModel.swift (プレイリスト一覧・編集用VM)
│   └── SettingsViewModel.swift (設定画面用VM)
├── Views
│   ├── Components              (再利用可能なUI部品)
│   ├── Player                  (再生プレイヤー関連画面)
│   ├── Playlist                (プレイリスト関連画面)
│   └── Settings                (設定画面)
└── Utilities
    └── Extensions.swift        (拡張機能など)
```

## 3. データフロー
1. **User Action**: ユーザーがViewを操作（ボタンタップ等）。
2. **ViewModel**: Viewからの入力を受け、Service (Model) のメソッドを呼び出す。
3. **Service**: APIリクエストなどを実行し、結果（データ）を取得。
4. **Model Update**: 取得したデータでModelを更新。
5. **ViewModel Update**: ViewModelがModelの変化を受け取り、自身のPublishedプロパティを更新。
6. **View Update**: SwiftUIの仕組みにより、ViewModelの変更が検知され、Viewが自動的に更新される。

## 4. 主要な技術選定
- **UI**: SwiftUI
- **通信**: URLSession (非同期処理にSwift Concurrency `async/await` を使用)
- **JSON解析**: Codable
- **認証**: ASWebAuthenticationSession (OAuth 2.0認可フロー用)

## 5. プレイリスト管理のUX改善設計
純正アプリに対する優位性である「楽曲管理のしやすさ」を実現するため、以下の設計を基本とする。

- **並び替え**: `onMove(perform:)` を活用したリストの並べ替え機能の実装。
- **削除**: スワイプ削除または編集モードによる一括削除。
- **追加**: 検索結果からのドラッグ＆ドロップ、またはコンテキストメニューによる追加。
