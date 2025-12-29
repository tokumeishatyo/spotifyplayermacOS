# SpotManager for macOS 🎵

**SpotManager** は、macOSネイティブで動作する軽量かつ高機能なSpotifyプレイリスト管理アプリケーションです。
SwiftUIで構築されており、公式のWebベースアプリ（Electron）と比較して圧倒的に軽快な動作を実現しています。

<p align="center">
  <img src="check/playlist.png" width="800" alt="Main Interface">
</p>

## ✨ 特徴 (Features)

### 🚀 Native & Blazing Fast
SwiftUIによるネイティブ実装のため、メモリ消費が少なく、起動も動作も一瞬です。作業をしながらバックグラウンドで起動していてもMacのパフォーマンスを落としません。

### 🎛️ 強力なプレイリスト管理
- **ドラッグ＆ドロップによる並び替え**: 直感的な操作で曲順を入れ替えることができます。
- **一括削除**: 複数の曲を選択して、コンテキストメニューから一発で削除可能。
- **3カラムデザイン**: サイドバー、トラックリスト、詳細情報の見やすいレイアウト。

### 🖥️ ミニプレイヤーモード
作業に集中したいときは、アルバムアートワークのみを表示する「ミニプレイヤー」に切り替え可能。デスクトップの片隅で邪魔になりません。

<p align="center">
  <img src="check/mini.png" width="300" alt="Mini Player">
</p>

### 🔒 安心のセキュリティ
- **PKCE認証**: 最新のセキュリティ標準である Authorization Code Flow with PKCE を採用。
- **Keychain連携**: 認証トークンはmacOSのKeychainに安全に保存され、アプリを再起動してもログイン状態が維持されます。

## 🛠️ 技術スタック (Tech Stack)

- **Language**: Swift 5
- **UI Framework**: SwiftUI (macOS)
- **Architecture**: MVVM
- **API**: Spotify Web API
- **Concurrency**: Swift Concurrency (Async/Await), Combine

## ⚙️ セットアップとビルド (Build Setup)

このプロジェクトをビルドするには、Spotify Developer Dashboardでの登録が必要です。

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/tokumeishatyo/spotifyplayermacOS.git
   cd spotifyplayermacOS
   ```

2. **Spotify Appの作成**
   - [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/) にアクセスし、Create Appを作成します。
   - **Redirect URI** に `spotifyplayer://callback` を設定してください。

3. **設定ファイルの作成**
   `spotifyplayer/Config.xcconfig` ファイルを新規作成し、以下の内容を記述します（このファイルは`.gitignore`されています）。
   ```properties
   SPOTIFY_CLIENT_ID = あなたのClientID
   // スラッシュのエスケープハック
   SPOTIFY_REDIRECT_URI = spotifyplayer:/$()/callback
   ```

4. **ビルド**
   `spotifyplayer.xcodeproj` をXcodeで開き、ターゲットを `SpotManager` にして実行します。

## 📝 License

MIT License
