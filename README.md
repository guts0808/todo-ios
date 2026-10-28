# TodoApp (iOS)

SwiftUI + SwiftData で作ったシンプルな TODO アプリです。

## 機能

- TODO の追加・編集・削除（タイトル / メモ / 期限日・時刻 / 優先度）
- 期限は日付のみ、または日付＋時刻で設定可能（時刻指定ありはその時刻を過ぎると期限切れ）
- チェックボタンまたは左スワイプで完了・未完了を切り替え
- 右スワイプで削除、メニューから完了済みを一括削除
- 「すべて / 未完了 / 完了」の絞り込み
- 作成日順・期限順・優先度順の並び替え（未完了が常に上）
- タイトル・メモの検索
- 期限切れは赤、今日が期限のものはオレンジで表示
- データは SwiftData で端末内に保存

## 動作環境

- iOS 17.0 以降
- Xcode 16 以降

## 構成

```
TodoApp/
├── TodoApp.swift               アプリのエントリーポイント
├── Models/
│   ├── TodoItem.swift          SwiftData モデル
│   ├── Priority.swift          優先度
│   └── TodoListOptions.swift   絞り込み・並び替え・検索ロジック
└── Views/
    ├── TodoListView.swift      一覧画面
    ├── TodoRowView.swift       一覧の行
    ├── TodoEditorView.swift    追加・編集画面
    └── PreviewSampleData.swift プレビュー用サンプルデータ
TodoAppTests/                   Swift Testing によるユニットテスト
```

## ビルド・実行

`TodoApp.xcodeproj` を Xcode で開き、シミュレータを選んで実行（⌘R）します。
実機で動かす場合は、Signing & Capabilities で Team を設定し、必要に応じて Bundle Identifier（`com.example.TodoApp`）を変更してください。

コマンドラインからテストする場合:

```sh
xcodebuild test -project TodoApp.xcodeproj -scheme TodoApp \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
