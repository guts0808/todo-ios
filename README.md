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

## アーキテクチャ

Clean Architecture に沿って 4 つの層に分けています。依存は常に内側（Domain）に向かい、Domain は他のどの層にも依存しません。

```
Presentation ──▶ Domain ◀── Data
      ▲                       ▲
      └──────── App ──────────┘   （App が全体を組み立てる）
```

| 層 | 役割 | 依存してよいもの |
| --- | --- | --- |
| **Domain** | エンティティ・ビジネスルール・ユースケース・リポジトリのプロトコル | Foundation のみ |
| **Data** | `TodoRepository` の実装（SwiftData / インメモリ） | Domain, SwiftData |
| **Presentation** | ViewModel（`@Observable`）と SwiftUI の View | Domain, SwiftUI |
| **App** | エントリーポイントと依存関係の組み立て（Composition Root） | すべて |

- View は ViewModel だけを見て、ViewModel はユースケース経由でデータを操作します。View や ViewModel は SwiftData を直接触りません。
- 保存先を差し替えたい場合（iCloud・サーバー API など）は、`TodoRepository` に準拠した実装を Data 層に追加し、`AppContainer` で渡すだけで済みます。

```
TodoApp/
├── App/
│   ├── TodoApp.swift                      エントリーポイント
│   └── AppContainer.swift                 依存関係の組み立て
├── Domain/
│   ├── Entities/                          Todo, Priority, TodoFilter, TodoSortOrder
│   ├── Services/TodoListArranger.swift    絞り込み・検索・並び替えのルール
│   ├── Repositories/TodoRepository.swift  永続化の抽象
│   └── UseCases/                          取得・保存・完了切替・削除・完了済み一括削除
├── Data/
│   ├── SwiftData/                         TodoRecord（@Model）と SwiftDataTodoRepository（@ModelActor）
│   └── InMemory/                          InMemoryTodoRepository（プレビュー・テスト用）
└── Presentation/
    ├── TodoList/                          一覧画面の View / ViewModel / 行
    ├── TodoEditor/                        追加・編集画面の View / ViewModel
    ├── Common/DisplayText.swift           ドメイン値の表示文言・色
    └── Preview/PreviewSupport.swift       プレビュー用サンプルデータ
TodoAppTests/                              層ごとのユニットテスト（Swift Testing）
```

## ビルド・実行

`TodoApp.xcodeproj` を Xcode で開き、シミュレータを選んで実行（⌘R）します。
実機で動かす場合は、Signing & Capabilities で Team を設定し、必要に応じて Bundle Identifier（`com.example.TodoApp`）を変更してください。

コマンドラインからテストする場合:

```sh
xcodebuild test -project TodoApp.xcodeproj -scheme TodoApp \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
