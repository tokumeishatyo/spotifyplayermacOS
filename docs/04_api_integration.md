<!-- rule.mdを読むこと -->
# 外部連携設計書 (API Integration)

## 1. Spotify Web API 概要
- **Base URL**: `https://api.spotify.com/v1`
- **認証方式**: Authorization Code Flow with PKCE (セキュリティ推奨)
- **トークンの永続化**: 
    - 取得した `refresh_token` を macOS の **Keychain** に安全に保存します。
    - アプリ起動時に Keychain からトークンを読み込み、有効な場合は自動的にアクセストークンを更新してログイン状態を復元します。
- **Scope**:
    - `user-read-private`, `user-read-email` (ユーザー情報)
    - `playlist-read-private`, `playlist-read-collaborative`, `playlist-modify-public`, `playlist-modify-private` (プレイリスト操作)
    - `streaming`, `app-remote-control`, `user-modify-playback-state`, `user-read-playback-state`, `user-read-currently-playing` (再生制御)

## 2. 実装予定のエンドポイント

### 2.1 ユーザー認証 & プロフィール
- `GET /me`: 現在のユーザー情報を取得（Premium会員チェックに使用）

### 2.2 プレイリスト操作
- `GET /me/playlists`: ユーザーのプレイリスト一覧取得
- `GET /playlists/{playlist_id}/tracks`: プレイリスト内の楽曲一覧取得
- `POST /users/{user_id}/playlists`: 新規プレイリスト作成（実装済み）
- **楽曲追加**:
    - `POST /playlists/{playlist_id}/tracks`: リクエストボディに `uris` (配列) を含めることで一括追加（実装済み）。
- **一括削除**:
    - `DELETE /playlists/{playlist_id}/tracks`: リクエストボディに `tracks` (URIを含むオブジェクト配列) を含めることで一括削除可能。
- **並び替え**:
    - `PUT /playlists/{playlist_id}/tracks`: `range_start` (移動元の開始位置), `insert_before` (移動先の位置), `range_length` (移動する個数) を指定して移動。

### 2.3 検索 & レコメンド
- **通常検索**:
    - `GET /search`: `q` パラメータにキーワード、`type` に `track,artist,album` を指定。
- **「その時の気分」検索 (Recommendations API)**:
    - `GET /recommendations`: Web APIのジャンルシード制約が大きく、安定した機能提供が困難なため、**実装見送り**。

### 2.4 再生コントロール
- `PUT /me/player/play`: 再生開始 / 再開
- `PUT /me/player/pause`: 一時停止
- `POST /me/player/next`: 次の曲
- `POST /me/player/previous`: 前の曲
- `PUT /me/player/shuffle`: シャッフル切り替え
- `PUT /me/player/repeat`: リピートモード切り替え
- `GET /me/player/devices`: 利用可能なデバイス一覧取得（再生先選択用）

## 3. エラーハンドリング
- **401 Unauthorized**: アクセストークンの有効期限切れ。リフレッシュトークンを使用してトークンを再取得する処理を実装する。
- **403 Forbidden**: Premium会員でない場合や、Scope不足の場合。ユーザーに適切なメッセージを表示する。
- **429 Too Many Requests**: レート制限。`Retry-After` ヘッダーの値に従って待機するロジックを入れる（簡易的な実装としては、一時的に操作をブロックする）。
